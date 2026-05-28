package br.com.simbora.piaui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

private const val TILE = 48f
private const val WORLD_W = 104
private const val WORLD_TOP_TILE = -8
private const val WORLD_H = 30
private const val PLAYER_SPEED = 150f

private const val OPENING_MISSION_ID = "boas_vindas_picos"
private const val OPENING_PHOTO_ID = "memoria_foto_entrada_picos"
private const val CHURCH_PHOTO_ID = "memoria_foto_igreja_matriz"
private const val FAIR_PHOTO_ID = "memoria_foto_feira_livre"
private const val MUSEUM_PHOTO_ID = "memoria_foto_museu_ozildo"
private const val PHASE1_ACCEPTED_ID = "fase1_diario_aceita"
private const val PHASE1_DONE_ID = "fase1_diario_concluida"
private const val CAPADOCIA_UNLOCKED_ID = "fase2_capadocia_liberada"
private const val PAGE_FEIRA_ID = "pagina_diario_feira"
private const val PAGE_MUSEU_ID = "pagina_diario_museu"
private const val PAGE_FEIRA_RELEASED_ID = "pagina_diario_feira_liberada"
private const val PAGE_MUSEU_RELEASED_ID = "pagina_diario_museu_liberada"

class NativeGameView(context: Context) : View(context) {
    private enum class Screen { MENU, PLAY }
    private enum class Panel { NONE, OPTIONS, MARKETPLACE, COLLECTION, TRAVEL_MAP, CAPADOCIA }
    private enum class Direction { DOWN, LEFT, RIGHT, UP }

    private data class Vec(var x: Float, var y: Float)
    private data class Prop(val type: String, val x: Int, val y: Int, val variant: Int = 0)
    private data class Mission(
        val id: String,
        val name: String,
        val npc: String,
        val item: String,
        val fact: String,
        val x: Int,
        val y: Int,
        val type: String = "mission",
        val requires: String? = null,
    )
    private data class Choice(val text: String, val action: () -> Unit)
    private data class DialogState(val title: String, val text: String, val choices: List<Choice>)

    private val prefs = context.getSharedPreferences("simbora_native", Context.MODE_PRIVATE)
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val uiPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val solids = mutableSetOf<String>()
    private val plazaTiles = mutableSetOf<String>()
    private val picosTiles = mutableSetOf<String>()
    private val roadTiles = mutableSetOf<String>()
    private val solidRects = mutableListOf<RectF>()
    private val props = mutableListOf<Prop>()
    private val missions = mutableListOf<Mission>()
    private val learned = mutableSetOf<String>()
    private val redeemed = mutableSetOf<String>()
    private val menuButtons = mutableListOf<Pair<RectF, () -> Unit>>()
    private val uiButtons = mutableListOf<Pair<RectF, () -> Unit>>()
    private val activePointers = mutableMapOf<Int, Vec>()

    private val assets = Assets()
    private var mediaPlayer: MediaPlayer? = null
    private var soundPool: SoundPool? = null
    private var cameraSoundId = 0

    private var screen = Screen.MENU
    private var panel = Panel.NONE
    private var dialog: DialogState? = null
    private var lastFrame = 0L
    private var running = false
    private var player = Vec(27f * TILE, 19f * TILE)
    private var camera = Vec(0f, 0f)
    private var direction = Direction.DOWN
    private var walkTime = 0f
    private var speed = PLAYER_SPEED
    private var flash = 0f
    private var selectedCharacter = prefs.getString("character", "male") ?: "male"
    private var musicVolume = prefs.getFloat("music_volume", 70f)
    private var sfxVolume = prefs.getFloat("sfx_volume", 80f)

    private var openingActive = true
    private var openingPhase = "intro"
    private var openingCameraCollected = false
    private var openingMemoryOpen = false
    private var openingMotoIndex = -1
    private var openingScriptIndex = -1
    private var phaseRewardIndex = -1
    private var donaQuizIndex = 0
    private var placeName = "Picos"
    private var hintText = "Passe pelo letreiro, pegue a câmera e encontre o mototáxi."

    private val picosChurch = Pair(33, 9)
    private val donaRita = Pair(54, 7)
    private val anaMuseu = Pair(68, 17)
    private val ozildoMuseum = Pair(73, 13)
    private val churchPlaza = Rect(17, -5, 81, 27)
    private val ozildoPlaza = Rect(46, 7, 91, 26)

    private val openingMotoLines = listOf(
        "Motoboy de Picos" to "Eita, chegou cedo! Eu sou o Naldo. Quer uma corrida pela entrada de Picos?",
        "Você" to "Quero sim. Estou procurando histórias da cidade e disseram que por aqui tudo começa na estrada.",
        "Motoboy de Picos" to "Pois disseram certo. Picos é passagem, encontro e pressa boa. Segura firme que eu te deixo perto da praça.",
        "Motoboy de Picos" to "Quando descer, vá até a praça da igreja. Seu Zé está esperando por você."
    )
    private val openingScriptLines = listOf(
        "Seu Zé das Lendas" to "Opa, meu jovem! Seja muito bem-vindo à nossa querida Picos! Está sentindo esse cheirinho doce no ar? Não é à toa que nos chamam de a Capital do Mel.",
        "Seu Zé das Lendas" to "Aproveite a sombra aqui da nossa imponente Igreja Matriz. Ela é o coração da cidade há muitas gerações.",
        "Seu Zé das Lendas" to "Mas hoje o vento soprou forte demais! Uma ventania daquelas espalhou as páginas do meu Diário das Raízes por toda a cidade.",
        "Seu Zé das Lendas" to "Eu já não tenho as pernas tão rápidas quanto as suas. Você poderia me ajudar a recuperar essas páginas?",
        "Seu Zé das Lendas" to "Se você trouxer as páginas, eu compartilho os segredos escritos nelas e te dou um item especial. O que me diz? SIM-BORA?"
    )
    private val rewardLines = listOf(
        "Seu Zé das Lendas" to "Rapaz, você conseguiu! Com essas páginas, a história de Picos está a salvo.",
        "Seu Zé das Lendas" to "Aqui fala de um lugar místico: uma cidade de pedras gigantes e avermelhadas, esculpidas pelo vento e pelo tempo.",
        "Jogador" to "Pedras gigantes? Onde fica isso?",
        "Seu Zé das Lendas" to "Fica em São José do Piauí, minha jovem águia! É a nossa famosa Capadócia Nordestina. Sim-Bora!"
    )
    private val donaRitaQuiz = listOf(
        Quiz(
            "Qual é o principal produto que faz Picos ser conhecida como capital em todo o Brasil?",
            listOf("A - A Cajuína.", "B - A Farinha de Mandioca.", "C - O Mel de Abelha.", "D - Castanha."),
            2,
            "Isso mesmo! Picos é conhecida como Capital do Mel. Mas Dona Rita ainda quer ver se você entende a força da feira."
        ),
        Quiz(
            "Na Feira Livre de Picos, o que as barracas ajudam a manter vivo na cidade?",
            listOf("A - Apenas a venda de produtos importados.", "B - O encontro entre trabalhadores, famílias, sabores e histórias do cotidiano.", "C - Um espaço fechado só para turistas.", "D - Um lugar usado apenas em datas comemorativas."),
            1,
            "Muito bem! A feira é lugar de trabalho, conversa e memória. Falta só uma para Dona Rita entregar o papel."
        ),
        Quiz(
            "Por que o mel é tão importante para a identidade econômica e cultural de Picos?",
            listOf("A - Porque representa a produção regional, o trabalho dos apicultores e o reconhecimento da cidade.", "B - Porque chegou pronto de outros estados para ser revendido.", "C - Porque substituiu todos os outros alimentos da feira.", "D - Porque é produzido apenas dentro do museu."),
            0,
            "Arretado! Você conhece mesmo a nossa terra."
        )
    )

    init {
        isFocusable = true
        textPaint.typeface = android.graphics.Typeface.create(android.graphics.Typeface.MONOSPACE, android.graphics.Typeface.BOLD)
        textPaint.color = Color.rgb(255, 247, 220)
        uiPaint.typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
        uiPaint.color = Color.rgb(255, 247, 220)
        loadProgress()
        assets.load()
        buildWorld()
        openingActive = !learned.contains(OPENING_MISSION_ID)
        if (!openingActive) {
            player = Vec(churchPlazaSpawn().x, churchPlazaSpawn().y)
        } else {
            player = Vec(190f, 1268f)
        }
        setupAudio()
    }

    fun resume() {
        running = true
        lastFrame = SystemClock.uptimeMillis()
        postInvalidateOnAnimation()
        mediaPlayer?.start()
    }

    fun pause() {
        running = false
        mediaPlayer?.pause()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val now = SystemClock.uptimeMillis()
        val dt = min(0.033f, ((now - lastFrame).coerceAtLeast(0)).toFloat() / 1000f)
        lastFrame = now
        if (running && screen == Screen.PLAY && panel == Panel.NONE && dialog == null && !anyMemoryOpen()) update(dt)

        if (screen == Screen.MENU) drawMenu(canvas) else drawGame(canvas)
        if (panel != Panel.NONE) drawPanel(canvas)
        dialog?.let { drawDialog(canvas, it) }
        if (flash > 0f) {
            paint.color = Color.argb((flash * 230).roundToInt(), 255, 255, 255)
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
            flash = max(0f, flash - dt * 3.2f)
        }
        if (running) postInvalidateOnAnimation()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val index = event.actionIndex
                val x = event.getX(index)
                val y = event.getY(index)
                val id = event.getPointerId(index)
                handleTap(x, y) ?: run { activePointers[id] = Vec(x, y) }
            }
            MotionEvent.ACTION_MOVE -> {
                for (i in 0 until event.pointerCount) {
                    activePointers[event.getPointerId(i)]?.let {
                        it.x = event.getX(i)
                        it.y = event.getY(i)
                    }
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_CANCEL -> {
                activePointers.remove(event.getPointerId(event.actionIndex))
            }
        }
        return true
    }

    private fun handleTap(x: Float, y: Float): Boolean? {
        val point = Vec(x, y)
        uiButtons.firstOrNull { it.first.contains(point.x, point.y) }?.second?.invoke()?.let { return true }
        if (screen == Screen.MENU) {
            menuButtons.firstOrNull { it.first.contains(point.x, point.y) }?.second?.invoke()
            return true
        }
        if (panel != Panel.NONE) {
            handlePanelTap(point)
            return true
        }
        dialog?.let { d ->
            val buttons = dialogButtonRects(d)
            buttons.firstOrNull { it.first.contains(point.x, point.y) }?.second?.action?.invoke()
            return true
        }
        if (anyMemoryOpen()) {
            closeCurrentMemory()
            return true
        }
        if (openingActive && openingPhase == "intro" && !openingCameraCollected && distance(player, openingCameraPos()) < 74f) {
            collectOpeningCamera()
            return true
        }
        return null
    }

    private fun update(dt: Float) {
        val move = readMoveVector()
        if (move.x != 0f || move.y != 0f) {
            val len = hypot(move.x, move.y)
            move.x /= len
            move.y /= len
            direction = if (abs(move.x) > abs(move.y)) {
                if (move.x > 0) Direction.RIGHT else Direction.LEFT
            } else {
                if (move.y > 0) Direction.DOWN else Direction.UP
            }
            walkTime += dt * 9f
            if (openingActive && openingPhase == "intro") moveOpeningIntro(move, dt) else {
                movePlayer(move.x * speed * dt, 0f)
                movePlayer(0f, move.y * speed * dt)
            }
        } else {
            walkTime = 0f
        }

        if (openingActive) updateOpeningHints() else placeName = nearestMission()?.name ?: "Picos"
        updateCamera()
    }

    private fun readMoveVector(): Vec {
        val move = Vec(0f, 0f)
        activePointers.values.forEach { p ->
            val dpad = dpadRect()
            if (dpad.contains(p.x, p.y)) {
                val cx = dpad.centerX()
                val cy = dpad.centerY()
                move.x += ((p.x - cx) / (dpad.width() * 0.32f)).coerceIn(-1f, 1f)
                move.y += ((p.y - cy) / (dpad.height() * 0.32f)).coerceIn(-1f, 1f)
            }
        }
        return move
    }

    private fun moveOpeningIntro(move: Vec, dt: Float) {
        player.x = (player.x + move.x * speed * dt).coerceIn(60f, 1820f)
        player.y = (player.y + move.y * speed * dt).coerceIn(1050f, 1390f)
    }

    private fun movePlayer(dx: Float, dy: Float) {
        val next = Vec(player.x + dx, player.y + dy)
        if (!collides(next)) player = next
    }

    private fun collides(pos: Vec): Boolean {
        if (pos.x < churchPlaza.left * TILE + 12f) return true
        val actor = RectF(pos.x - 12f, pos.y + 8f, pos.x + 12f, pos.y + 20f)
        if (solidRects.any { RectF.intersects(actor, it) }) return true
        val left = floor((pos.x - 12f) / TILE).toInt()
        val right = floor((pos.x + 12f) / TILE).toInt()
        val top = floor((pos.y + 8f) / TILE).toInt()
        val bottom = floor((pos.y + 20f) / TILE).toInt()
        for (tx in left..right) for (ty in top..bottom) if (solids.contains(key(tx, ty))) return true
        return false
    }

    private fun updateOpeningHints() {
        placeName = "Picos"
        if (openingPhase == "intro") {
            val nearCamera = !openingCameraCollected && distance(player, openingCameraPos()) < 74f
            val nearMoto = distance(player, openingMotoPos()) < 94f
            hintText = when {
                nearCamera -> "Toque em F para pegar a câmera."
                nearMoto -> "Toque em F no mototáxi para seguir viagem."
                else -> "Pegue a câmera perto do letreiro e encontre o mototáxi."
            }
        } else {
            val nearZe = near(player, seuZePos(), 125f)
            openingPhase = if (nearZe) "meet" else "walk"
            hintText = if (nearZe) "Toque em F para falar com Seu Zé." else "Siga até Seu Zé na praça da igreja."
        }
    }

    private fun updateCamera() {
        val targetX = if (openingActive && openingPhase == "intro") 0f else player.x - width / 2f
        val targetY = if (openingActive && openingPhase == "intro") 980f else player.y - height / 2f
        camera.x += (targetX - camera.x) * 0.12f
        camera.y += (targetY - camera.y) * 0.12f
        val minX = if (openingActive && openingPhase == "intro") 0f else churchPlaza.left * TILE
        val maxX = if (openingActive && openingPhase == "intro") 1920f - width else WORLD_W * TILE - width
        camera.x = camera.x.coerceIn(minX, max(minX, maxX))
        camera.y = camera.y.coerceIn(WORLD_TOP_TILE * TILE, max(WORLD_TOP_TILE * TILE, WORLD_H * TILE - height))
    }

    private fun interact() {
        if (screen == Screen.MENU) {
            startGame()
            return
        }
        if (panel != Panel.NONE) {
            panel = Panel.NONE
            return
        }
        dialog?.let {
            if (it.choices.size == 1) it.choices[0].action() else dialog = null
            return
        }
        if (anyMemoryOpen()) {
            closeCurrentMemory()
            return
        }
        if (openingActive) {
            interactOpening()
            return
        }
        when {
            canCollectPhoto(CHURCH_PHOTO_ID, churchPhotoPos()) -> takePhoto(CHURCH_PHOTO_ID)
            canCollectPhoto(FAIR_PHOTO_ID, fairPhotoPos()) -> takePhoto(FAIR_PHOTO_ID)
            canCollectPhoto(MUSEUM_PHOTO_ID, museumPhotoPos()) -> takePhoto(MUSEUM_PHOTO_ID)
            nearestMission()?.type == "diary_page" && !learned.contains(nearestMission()!!.id) -> collectDiary(nearestMission()!!)
            near(player, seuZePos(), 125f) -> interactSeuZe()
            near(player, Vec(donaRita.first * TILE, donaRita.second * TILE), 105f) -> interactDonaRita()
            near(player, Vec(anaMuseu.first * TILE, anaMuseu.second * TILE), 105f) -> interactAna()
            else -> showDialog("Picos", "Explore a cidade livremente.")
        }
    }

    private fun interactOpening() {
        if (openingPhase == "intro") {
            when {
                !openingCameraCollected && near(player, openingCameraPos(), 74f) -> collectOpeningCamera()
                near(player, openingMotoPos(), 94f) -> startMotoDialog()
                else -> hintText = "Pegue a câmera ou chegue perto do mototáxi."
            }
            return
        }
        if (openingPhase == "meet" && near(player, seuZePos(), 125f)) startOpeningScript()
    }

    private fun startMotoDialog() {
        openingMotoIndex = 0
        showMotoLine()
    }

    private fun showMotoLine() {
        if (openingMotoIndex >= openingMotoLines.size) {
            dialog = null
            openingPhase = "meet"
            player = churchPlazaSpawn()
            direction = Direction.UP
            return
        }
        val line = openingMotoLines[openingMotoIndex]
        dialog = DialogState(line.first, line.second, listOf(Choice("Continuar") {
            openingMotoIndex += 1
            showMotoLine()
        }))
    }

    private fun collectOpeningCamera() {
        openingCameraCollected = true
        openingMemoryOpen = true
        learned.add(OPENING_PHOTO_ID)
        flash = 1f
        hintText = "Nova Memória adicionada ao Diário de Bordo!"
        saveProgress()
        playCameraSound()
    }

    private fun startOpeningScript() {
        openingScriptIndex = 0
        showOpeningLine()
    }

    private fun showOpeningLine() {
        if (openingScriptIndex >= openingScriptLines.size) {
            dialog = null
            openingActive = false
            learned.add(OPENING_MISSION_ID)
            learned.add(PHASE1_ACCEPTED_ID)
            saveProgress()
            showDialog("Missão aceita", "Objetivo: recuperar as páginas do Diário das Raízes na Feira Livre e perto do Museu Ozildo Albano.")
            return
        }
        val line = openingScriptLines[openingScriptIndex]
        dialog = DialogState(line.first, line.second, listOf(Choice("Continuar") {
            openingScriptIndex += 1
            showOpeningLine()
        }))
    }

    private fun interactSeuZe() {
        when {
            !learned.contains(PHASE1_ACCEPTED_ID) -> startOpeningScript()
            learned.contains(CAPADOCIA_UNLOCKED_ID) || learned.contains(PHASE1_DONE_ID) -> panel = Panel.TRAVEL_MAP
            learned.contains(PAGE_FEIRA_ID) && learned.contains(PAGE_MUSEU_ID) -> startReward()
            else -> showDialog("Seu Zé das Lendas", "A Feira Livre costuma ser bem movimentada; procure com atenção por lá! A outra página deve estar perto do Museu Ozildo Albano.")
        }
    }

    private fun startReward() {
        phaseRewardIndex = 0
        showRewardLine()
    }

    private fun showRewardLine() {
        if (phaseRewardIndex >= rewardLines.size) {
            learned.add(PHASE1_DONE_ID)
            learned.add(CAPADOCIA_UNLOCKED_ID)
            saveProgress()
            dialog = null
            panel = Panel.TRAVEL_MAP
            return
        }
        val line = rewardLines[phaseRewardIndex]
        dialog = DialogState(line.first, line.second, listOf(Choice("Continuar") {
            phaseRewardIndex += 1
            showRewardLine()
        }))
    }

    private fun interactDonaRita() {
        if (learned.contains(PAGE_FEIRA_ID)) {
            showDialog("Dona Rita", "Arretado! Já entreguei o papel que caiu nos sacos de castanha. Vá com Deus na sua missão!")
            return
        }
        dialog = DialogState(
            "Dona Rita",
            "Ei, menino! Cuidado por onde anda, que a feira hoje está um fervo! Vai levar uma cajuína gelada pra rebater esse calor?",
            listOf(
                Choice("A - Estou procurando uma página de um diário antigo.") { showDonaClue() },
                Choice("B - Só estou olhando as barracas mesmo.") { showDialog("Dona Rita", "Pois olhe com calma. Sempre cabe mais uma história entre uma banca e outra.") }
            )
        )
    }

    private fun showDonaClue() {
        dialog = DialogState(
            "Dona Rita",
            "Ah, aquele papel amarelo? Caiu bem ali no meio dos sacos de castanha. Eu só te entrego se você provar que conhece a nossa terra.",
            listOf(Choice("Responder") {
                donaQuizIndex = 0
                showDonaQuiz()
            })
        )
    }

    private fun showDonaQuiz() {
        val quiz = donaRitaQuiz[donaQuizIndex]
        dialog = DialogState(
            "Dona Rita",
            "Pergunta ${donaQuizIndex + 1} de ${donaRitaQuiz.size}\n\n${quiz.question}",
            quiz.options.mapIndexed { index, option ->
                Choice(option) { answerDonaQuiz(index) }
            }
        )
    }

    private fun answerDonaQuiz(index: Int) {
        val quiz = donaRitaQuiz[donaQuizIndex]
        if (index == quiz.answer) {
            if (donaQuizIndex == donaRitaQuiz.lastIndex) {
                learned.add(PAGE_FEIRA_RELEASED_ID)
                saveProgress()
                showDialog("Dona Rita", "Arretado! O papel está ali pertinho dos sacos de castanha: pegue-o para guardar na mochila.")
            } else {
                donaQuizIndex += 1
                dialog = DialogState("Dona Rita", quiz.success, listOf(Choice("Próxima pergunta") { showDonaQuiz() }))
            }
        } else {
            dialog = DialogState("Dona Rita", "Ainda não foi dessa vez. Pense com calma e tente de novo.", listOf(Choice("Tentar novamente") { showDonaQuiz() }))
        }
    }

    private fun interactAna() {
        when {
            learned.contains(PAGE_MUSEU_ID) -> showDialog("Ana", "Você já recebeu a página do Seu Zé. Continue sua jornada com esse olhar curioso pela nossa história!")
            !learned.contains(PHASE1_ACCEPTED_ID) -> showDialog("Ana", "Olá! Seja bem-vindo ao Museu Ozildo Albano. Este espaço guarda a memória viva de Picos e do Vale do Rio Guaribas!")
            else -> showAnaIntro()
        }
    }

    private fun showAnaIntro() {
        dialog = DialogState("Ana", "Olá! Seja bem-vindo ao Museu Ozildo Albano. Este espaço guarda a memória viva de Picos e de todo o Vale do Rio Guaribas!", listOf(Choice("Continuar") {
            dialog = DialogState("Jogador", "Estou ajudando o Seu Zé. Uma página do diário dele voou pela janela e disseram que caiu por aqui.", listOf(Choice("Continuar") {
                dialog = DialogState("Ana", "Ela caiu aqui enquanto eu limpava esta imagem de Santa Ana Mestra. Prove que conhece o valor da nossa história e eu lhe entrego a página.", listOf(Choice("Responder") { showAnaQuiz() }))
            }))
        }))
    }

    private fun showAnaQuiz() {
        val options = listOf(
            "A - Foi construído por uma grande empresa que encontrou objetos soterrados.",
            "B - Nasceu da iniciativa do colecionador Ozildo Albano, que reuniu peças da família e da região.",
            "C - Foi criado para guardar exclusivamente o tesouro do Império.",
            "D - Foi fundado apenas por igrejas locais."
        )
        dialog = DialogState("Ana", "Como o Museu Ozildo Albano iniciou sua história no ano de 1968?", options.mapIndexed { index, text ->
            Choice(text) {
                if (index == 1) {
                    learned.add(PAGE_MUSEU_RELEASED_ID)
                    saveProgress()
                    showDialog("Ana", "Exatamente! O professor Ozildo começou o museu na própria casa. A página caiu ali pertinho: pegue-a para guardar na mochila.")
                } else {
                    showDialog("Ana", "Ainda não foi dessa vez. Observe melhor a história do museu e tente responder novamente.")
                }
            }
        })
    }

    private fun collectDiary(mission: Mission) {
        if (mission.requires != null && !learned.contains(mission.requires)) {
            showDialog(mission.npc, "Converse primeiro com quem guarda a pista desta página.")
            return
        }
        learned.add(mission.id)
        saveProgress()
        showDialog(mission.item, "${mission.fact}\n\nLeve esta página de volta para Seu Zé quando encontrar todas.")
    }

    private fun showDialog(title: String, text: String) {
        dialog = DialogState(title, text, listOf(Choice("Continuar") { dialog = null }))
    }

    private fun nearestMission(): Mission? {
        return missions
            .filter { it.requires == null || learned.contains(it.requires) }
            .minByOrNull { distance(player, Vec(it.x * TILE, it.y * TILE)) }
            ?.takeIf { distance(player, Vec(it.x * TILE, it.y * TILE)) < 116f }
    }

    private fun canCollectPhoto(id: String, pos: Vec) = !learned.contains(id) && near(player, pos, 70f)

    private fun takePhoto(id: String) {
        learned.add(id)
        flash = 1f
        saveProgress()
        playCameraSound()
        when (id) {
            CHURCH_PHOTO_ID -> showMemory("Igreja Matriz", assets.churchMemory)
            FAIR_PHOTO_ID -> showMemory("Feira Livre", assets.fairMemory)
            MUSEUM_PHOTO_ID -> showMemory("Museu Ozildo Albano", assets.museumMemory)
        }
    }

    private var memoryTitle: String? = null
    private var memoryBitmap: Bitmap? = null
    private fun showMemory(title: String, bitmap: Bitmap?) {
        memoryTitle = title
        memoryBitmap = bitmap
    }
    private fun anyMemoryOpen() = openingMemoryOpen || memoryTitle != null
    private fun closeCurrentMemory() {
        if (openingMemoryOpen) {
            openingMemoryOpen = false
            hintText = "O mototáxi está chegando para falar com você."
        }
        memoryTitle = null
        memoryBitmap = null
    }

    private fun drawMenu(canvas: Canvas) {
        menuButtons.clear()
        paint.color = Color.rgb(16, 24, 39)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        assets.menu?.let { drawCover(canvas, it, RectF(0f, 0f, width.toFloat(), height.toFloat())) }
        val scale = min(width / 1694f, height / 928f)
        fun sourceRect(x: Float, y: Float, w: Float, h: Float) =
            RectF((width - 1694f * scale) / 2f + x * scale, (height - 928f * scale) / 2f + y * scale, (width - 1694f * scale) / 2f + (x + w) * scale, (height - 928f * scale) / 2f + (y + h) * scale)
        drawImageButton(canvas, assets.buttonPlay, sourceRect(631f, 424f, 432f, 134f)) { startGame() }
        drawImageButton(canvas, assets.buttonOptions, sourceRect(622f, 544f, 451f, 93f)) { panel = Panel.OPTIONS; screen = Screen.PLAY }
        drawImageButton(canvas, assets.buttonMarket, sourceRect(584f, 629f, 525f, 116f)) { panel = Panel.MARKETPLACE; screen = Screen.PLAY }
        val gear = RectF(width - 78f, 18f, width - 18f, 78f)
        drawGoldButton(canvas, gear, "⚙")
        menuButtons.add(gear to { panel = Panel.OPTIONS; screen = Screen.PLAY })
    }

    private fun drawImageButton(canvas: Canvas, bitmap: Bitmap?, rect: RectF, action: () -> Unit) {
        bitmap?.let { canvas.drawBitmap(it, null, rect, null) } ?: drawGoldButton(canvas, rect, "Botão")
        menuButtons.add(rect to action)
    }

    private fun startGame() {
        screen = Screen.PLAY
        panel = Panel.NONE
        mediaPlayer?.start()
    }

    private fun drawGame(canvas: Canvas) {
        uiButtons.clear()
        if (openingActive && openingPhase == "intro") {
            drawOpeningIntro(canvas)
        } else {
            drawWorld(canvas)
        }
        drawHud(canvas)
        drawTouchControls(canvas)
        drawMemoryCard(canvas)
    }

    private fun drawOpeningIntro(canvas: Canvas) {
        val sky = LinearGradient(0f, 0f, 0f, height.toFloat(), Color.rgb(73, 167, 242), Color.rgb(247, 207, 132), Shader.TileMode.CLAMP)
        paint.shader = sky
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        paint.shader = null
        canvas.save()
        canvas.translate(-camera.x, -camera.y)
        val ground = 1268f
        paint.color = Color.rgb(214, 177, 106)
        canvas.drawRect(0f, ground - 18f, 2300f, 1720f, paint)
        paint.color = Color.rgb(122, 124, 120)
        canvas.drawRect(0f, ground + 18f, 2300f, ground + 92f, paint)
        assets.sign?.let { canvas.drawBitmap(it, null, RectF(180f, 980f, 680f, 1180f), null) }
        assets.camera?.let { canvas.drawBitmap(it, null, RectF(openingCameraPos().x - 24f, openingCameraPos().y - 46f, openingCameraPos().x + 36f, openingCameraPos().y + 20f), null) }
        drawMoto(canvas, openingMotoPos())
        drawPlayer(canvas, player.x, player.y)
        canvas.restore()
        drawHint(canvas)
    }

    private fun drawWorld(canvas: Canvas) {
        paint.color = Color.rgb(111, 185, 95)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        canvas.save()
        canvas.translate(-camera.x, -camera.y)
        drawGround(canvas)
        drawRoads(canvas)
        drawProps(canvas)
        drawMissions(canvas)
        drawPhotoMarkers(canvas)
        drawPlayer(canvas, player.x, player.y)
        canvas.restore()
    }

    private fun drawGround(canvas: Canvas) {
        val left = floor(camera.x / TILE).toInt() - 1
        val right = floor((camera.x + width) / TILE).toInt() + 1
        val top = floor(camera.y / TILE).toInt() - 1
        val bottom = floor((camera.y + height) / TILE).toInt() + 1
        for (x in left..right) for (y in top..bottom) {
            val px = x * TILE
            val py = y * TILE
            val tileRect = RectF(px, py, px + TILE, py + TILE)
            when {
                plazaTiles.contains(key(x, y)) -> {
                    paint.color = Color.rgb(215, 200, 165)
                    canvas.drawRect(tileRect, paint)
                }
                picosTiles.contains(key(x, y)) -> {
                    assets.dirt?.let { canvas.drawBitmap(it, null, tileRect, null) }
                        ?: run {
                            paint.color = Color.rgb(185, 160, 92)
                            canvas.drawRect(tileRect, paint)
                        }
                }
                else -> {
                    assets.grass?.let { canvas.drawBitmap(it, null, tileRect, null) }
                        ?: run {
                            paint.color = Color.rgb(113, 173, 90)
                            canvas.drawRect(tileRect, paint)
                        }
                }
            }
        }
        assets.ozildoPhoto?.let {
            canvas.drawBitmap(it, null, RectF(8f * TILE, 3f * TILE, 25f * TILE, 12f * TILE), null)
        }
        assets.churchPlaza?.let {
            canvas.drawBitmap(it, null, RectF(18f * TILE, 12f * TILE, 48f * TILE, 24f * TILE), null)
        }
        assets.museumPlaza?.let {
            canvas.drawBitmap(it, null, RectF(46f * TILE, 7f * TILE, 91f * TILE, 26f * TILE), null)
        }
    }

    private fun drawRoads(canvas: Canvas) {
        drawAsphaltStrip(canvas, RectF(20f * TILE, 14.4f * TILE, 92f * TILE, 16.2f * TILE))
        drawAsphaltStrip(canvas, RectF(38.8f * TILE, -5f * TILE, 40.6f * TILE, 27f * TILE))
        paint.color = Color.rgb(239, 232, 201)
        for (x in 20..92 step 4) canvas.drawRect(x * TILE, 15.2f * TILE, x * TILE + 34f, 15.32f * TILE, paint)
    }

    private fun drawAsphaltStrip(canvas: Canvas, rect: RectF) {
        assets.asphalt?.let { asphalt ->
            var x = rect.left
            while (x < rect.right) {
                var y = rect.top
                while (y < rect.bottom) {
                    canvas.drawBitmap(asphalt, null, RectF(x, y, min(x + TILE, rect.right), min(y + TILE, rect.bottom)), null)
                    y += TILE
                }
                x += TILE
            }
        } ?: run {
            paint.color = Color.rgb(96, 96, 92)
            canvas.drawRect(rect, paint)
        }
    }

    private fun drawProps(canvas: Canvas) {
        props.sortedBy { propDepth(it) }.forEach { prop ->
            val x = prop.x * TILE
            val y = prop.y * TILE
            when (prop.type) {
                "church" -> assets.church?.let { canvas.drawBitmap(it, null, RectF(x - 198f, y - 360f, x + 307f, y + 85f), null) } ?: drawLandmarkFallback(canvas, x, y)
                "museum" -> assets.museum?.let { canvas.drawBitmap(it, null, RectF(x - 180f, y - 190f, x + 470f, y + 260f), null) } ?: drawLandmarkFallback(canvas, x, y)
                "feira_roupas" -> assets.feiraRoupas?.let { canvas.drawBitmap(it, null, RectF(x, y, x + 900f, y + 285f), null) }
                "feira_bancas" -> assets.feiraBancas?.let { canvas.drawBitmap(it, null, RectF(x, y, x + 805f, y + 245f), null) }
                "feira_vertical" -> assets.feiraAdaptada?.let { canvas.drawBitmap(it, null, RectF(x - 106f, y - 12f, x + 154f, y + 370f), null) }
                "dona" -> drawCharacterSheet(canvas, assets.donaRita, x, y, 96, 160, 8, 61, 132f)
                "ana" -> drawCharacterSheet(canvas, assets.ana, x, y, 112, 160, 5, 20, 132f)
                "lamp" -> drawLamp(canvas, x, y)
                "bench" -> drawBench(canvas, x, y)
                "cactus" -> drawPropBitmap(canvas, assets.cactus, x, y, 74f)
                "aroeira", "malungu", "manga", "manga_diferente", "umbu", "ype" -> drawPropBitmap(canvas, assets.trees[prop.type], x, y, 104f)
                "buriti" -> drawPropBitmap(canvas, assets.trees[prop.type], x, y, 132f)
                "seu_ze" -> drawPropBitmap(canvas, assets.seuZe, x, y, 150f)
                "sign" -> assets.sign?.let { canvas.drawBitmap(it, null, RectF(x - 200f, y - 80f, x + 300f, y + 120f), null) }
            }
        }
    }

    private fun propDepth(prop: Prop): Float = when (prop.type) {
        "church" -> prop.y + 6f
        "museum" -> prop.y + 4f
        "feira_roupas", "feira_bancas", "feira_vertical" -> prop.y + 3.4f
        "dona", "ana", "seu_ze" -> prop.y + 2.6f
        "buriti" -> prop.y + 2.4f
        "aroeira", "malungu", "manga", "manga_diferente", "umbu", "ype", "cactus" -> prop.y + 1.8f
        else -> prop.y.toFloat()
    }

    private fun drawMissions(canvas: Canvas) {
        missions.forEach { mission ->
            if (mission.requires != null && !learned.contains(mission.requires)) return@forEach
            if (mission.type == "diary_page" && learned.contains(mission.id)) return@forEach
            val x = mission.x * TILE
            val y = mission.y * TILE
            paint.color = if (learned.contains(mission.id)) Color.rgb(255, 194, 71) else Color.rgb(255, 247, 220)
            canvas.drawCircle(x, y - 34f, 12f + sin(SystemClock.uptimeMillis() / 180.0).toFloat() * 2f, paint)
            if (mission.type == "diary_page") {
                assets.paper?.let { canvas.drawBitmap(it, null, RectF(x - 18f, y - 52f, x + 18f, y - 16f), null) }
                    ?: run { paint.color = Color.rgb(245, 230, 184); canvas.drawRect(x - 13f, y - 48f, x + 13f, y - 14f, paint) }
            }
        }
    }

    private fun drawPhotoMarkers(canvas: Canvas) {
        listOf(CHURCH_PHOTO_ID to churchPhotoPos(), FAIR_PHOTO_ID to fairPhotoPos(), MUSEUM_PHOTO_ID to museumPhotoPos()).forEach { (id, pos) ->
            if (!learned.contains(id)) {
                assets.camera?.let { canvas.drawBitmap(it, null, RectF(pos.x - 22f, pos.y - 40f, pos.x + 34f, pos.y + 16f), null) }
            }
        }
    }

    private fun drawCharacterSheet(canvas: Canvas, sheet: Bitmap?, x: Float, y: Float, fw: Int, fh: Int, cols: Int, count: Int, drawH: Float) {
        if (sheet == null) {
            drawNpc(canvas, x, y)
            return
        }
        val frame = ((SystemClock.uptimeMillis() / 100) % count).toInt()
        val src = Rect((frame % cols) * fw, (frame / cols) * fh, (frame % cols + 1) * fw, (frame / cols + 1) * fh)
        val drawW = drawH * fw / fh
        canvas.drawBitmap(sheet, src, RectF(x - drawW / 2f, y - drawH + 18f, x + drawW / 2f, y + 18f), null)
    }

    private fun drawPlayer(canvas: Canvas, x: Float, y: Float) {
        paint.color = Color.argb(55, 0, 0, 0)
        canvas.drawOval(RectF(x - 14f, y + 16f, x + 14f, y + 23f), paint)
        val sheet = if (selectedCharacter == "female") assets.playerFemale else assets.playerMale
        if (sheet != null) {
            val frame = if (walkTime > 0f) ((walkTime * 0.7f).toInt() % 4) else 0
            val sx = intArrayOf(167, 409, 648, 887)[frame]
            val sy = when (direction) {
                Direction.DOWN -> 70
                Direction.LEFT -> 360
                Direction.RIGHT -> 640
                Direction.UP -> 918
            }
            canvas.drawBitmap(sheet, Rect(sx, sy, sx + 220, sy + 300), RectF(x - 33f, y - 72f, x + 33f, y + 18f), null)
        } else {
            paint.color = Color.rgb(217, 107, 40)
            canvas.drawRect(x - 14f, y - 34f, x + 14f, y, paint)
            paint.color = Color.rgb(242, 209, 122)
            canvas.drawRect(x - 18f, y - 48f, x + 18f, y - 36f, paint)
        }
    }

    private fun drawHud(canvas: Canvas) {
        drawPanelRect(canvas, RectF(12f, 10f, 250f, 54f), Color.argb(220, 18, 36, 74), Color.rgb(255, 194, 71))
        drawText(canvas, placeName, 28f, 39f, 18f, Color.rgb(255, 247, 220), Paint.Align.LEFT)
        drawPanelRect(canvas, RectF(width - 222f, 10f, width - 12f, 54f), Color.argb(220, 18, 36, 74), Color.rgb(255, 194, 71))
        drawText(canvas, "Saberes ${learnedCount()}/${missions.size + 1}", width - 117f, 39f, 17f, Color.rgb(255, 247, 220), Paint.Align.CENTER)
        val bag = RectF(width - 96f, 68f, width - 20f, 144f)
        drawGoldButton(canvas, bag, "Mochila")
        uiButtons.add(bag to { panel = Panel.COLLECTION })
        val opts = RectF(width - 80f, 154f, width - 20f, 214f)
        drawGoldButton(canvas, opts, "⚙")
        uiButtons.add(opts to { panel = Panel.OPTIONS })
        if (openingActive) drawHint(canvas)
    }

    private fun drawHint(canvas: Canvas) {
        val rect = RectF(32f, height - 98f, width - 32f, height - 58f)
        drawPanelRect(canvas, rect, Color.argb(200, 58, 29, 17), Color.rgb(255, 194, 71))
        drawText(canvas, hintText, rect.centerX(), rect.centerY() + 6f, 15f, Color.rgb(255, 247, 220), Paint.Align.CENTER, rect.width() - 18f)
    }

    private fun drawTouchControls(canvas: Canvas) {
        val dpad = dpadRect()
        paint.color = Color.argb(116, 30, 22, 16)
        canvas.drawRoundRect(dpad, 12f, 12f, paint)
        drawText(canvas, "▲", dpad.centerX(), dpad.top + 45f, 28f, Color.WHITE, Paint.Align.CENTER)
        drawText(canvas, "◀", dpad.left + 42f, dpad.centerY() + 10f, 28f, Color.WHITE, Paint.Align.CENTER)
        drawText(canvas, "▶", dpad.right - 42f, dpad.centerY() + 10f, 28f, Color.WHITE, Paint.Align.CENTER)
        drawText(canvas, "▼", dpad.centerX(), dpad.bottom - 20f, 28f, Color.WHITE, Paint.Align.CENTER)
        val action = RectF(width - 126f, height - 126f, width - 30f, height - 30f)
        drawPanelRect(canvas, action, Color.rgb(196, 61, 50), Color.rgb(255, 230, 167), 40f)
        drawText(canvas, "F", action.centerX(), action.centerY() + 12f, 32f, Color.WHITE, Paint.Align.CENTER)
        uiButtons.add(action to { interact() })
    }

    private fun drawMemoryCard(canvas: Canvas) {
        if (!anyMemoryOpen()) return
        val rect = RectF(width * 0.5f - 210f, height * 0.5f - 170f, width * 0.5f + 210f, height * 0.5f + 170f)
        drawPanelRect(canvas, rect, Color.rgb(255, 247, 220), Color.rgb(139, 75, 32), 8f)
        val title = memoryTitle ?: "Primeira Memória"
        val bitmap = memoryBitmap ?: assets.memoryPolaroid
        bitmap?.let { canvas.drawBitmap(it, null, RectF(rect.left + 24f, rect.top + 28f, rect.right - 24f, rect.bottom - 92f), null) }
        drawText(canvas, title, rect.centerX(), rect.bottom - 56f, 24f, Color.rgb(58, 29, 17), Paint.Align.CENTER)
        drawText(canvas, "Toque para continuar", rect.centerX(), rect.bottom - 24f, 15f, Color.rgb(58, 29, 17), Paint.Align.CENTER)
    }

    private fun drawPanel(canvas: Canvas) {
        when (panel) {
            Panel.OPTIONS -> drawOptions(canvas)
            Panel.MARKETPLACE -> drawMarketplace(canvas)
            Panel.COLLECTION -> drawCollection(canvas)
            Panel.TRAVEL_MAP -> drawTravelMap(canvas)
            Panel.CAPADOCIA -> drawCapadocia(canvas)
            Panel.NONE -> Unit
        }
    }

    private fun drawOptions(canvas: Canvas) {
        val rect = modalRect()
        drawPanelRect(canvas, rect, Color.argb(245, 58, 29, 17), Color.rgb(255, 194, 71))
        drawText(canvas, "Opções", rect.left + 22f, rect.top + 42f, 28f, Color.rgb(255, 194, 71), Paint.Align.LEFT)
        val rows = listOf("Personagem: ${if (selectedCharacter == "male") "Masculino" else "Feminino"}", "Volume música: ${musicVolume.toInt()}%", "Volume efeitos: ${sfxVolume.toInt()}%", "Zerar progresso")
        rows.forEachIndexed { i, text ->
            val r = RectF(rect.left + 22f, rect.top + 70f + i * 58f, rect.right - 22f, rect.top + 118f + i * 58f)
            drawGoldButton(canvas, r, text)
            uiButtons.add(r to {
                when (i) {
                    0 -> { selectedCharacter = if (selectedCharacter == "male") "female" else "male"; saveSettings() }
                    1 -> { musicVolume = ((musicVolume + 10f) % 110f); saveSettings(); mediaPlayer?.setVolume(musicVolume / 100f, musicVolume / 100f) }
                    2 -> { sfxVolume = ((sfxVolume + 10f) % 110f); saveSettings() }
                    3 -> { learned.clear(); redeemed.clear(); openingActive = true; openingPhase = "intro"; player = Vec(190f, 1268f); saveProgress() }
                }
            })
        }
        drawClose(canvas, rect)
    }

    private fun drawMarketplace(canvas: Canvas) {
        val rect = modalRect()
        drawPanelRect(canvas, rect, Color.argb(245, 58, 29, 17), Color.rgb(255, 194, 71))
        drawText(canvas, "Marketplace", rect.left + 22f, rect.top + 42f, 28f, Color.rgb(255, 194, 71), Paint.Align.LEFT)
        val products = listOf("mapa" to "Mapa dos Parques", "caderno" to "Caderno de Campo", "passe" to "Passe Urbano")
        products.forEachIndexed { index, product ->
            val r = RectF(rect.left + 22f, rect.top + 78f + index * 62f, rect.right - 22f, rect.top + 130f + index * 62f)
            val cost = index * 2 + 1
            drawGoldButton(canvas, r, "${product.second} - $cost saber(es)")
            uiButtons.add(r to {
                if (learnedCount() >= cost) redeemed.add(product.first)
                saveProgress()
            })
        }
        drawText(canvas, "Saberes disponíveis: ${learnedCount()}/${missions.size + 1}", rect.left + 24f, rect.bottom - 38f, 16f, Color.rgb(255, 247, 220), Paint.Align.LEFT)
        drawClose(canvas, rect)
    }

    private fun drawCollection(canvas: Canvas) {
        val rect = modalRect()
        drawPanelRect(canvas, rect, Color.argb(248, 46, 23, 11), Color.rgb(139, 75, 32))
        drawText(canvas, "Coleção Cultural", rect.left + 22f, rect.top + 42f, 28f, Color.rgb(255, 194, 71), Paint.Align.LEFT)
        val memories = listOf(
            OPENING_PHOTO_ID to "Primeira Memória",
            CHURCH_PHOTO_ID to "Igreja Matriz",
            FAIR_PHOTO_ID to "Feira Livre",
            MUSEUM_PHOTO_ID to "Museu Ozildo Albano",
            PAGE_FEIRA_ID to "Página da Feira Livre",
            PAGE_MUSEU_ID to "Página do Museu"
        )
        memories.forEachIndexed { i, item ->
            val y = rect.top + 78f + i * 42f
            val text = if (learned.contains(item.first)) item.second else "Item oculto"
            drawText(canvas, text, rect.left + 32f, y + 25f, 17f, Color.rgb(255, 247, 220), Paint.Align.LEFT, rect.width() - 64f)
        }
        drawClose(canvas, rect)
    }

    private fun drawTravelMap(canvas: Canvas) {
        paint.color = Color.argb(210, 8, 6, 4)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        val rect = RectF(width * 0.1f, height * 0.12f, width * 0.9f, height * 0.88f)
        drawPanelRect(canvas, rect, Color.rgb(234, 213, 159), Color.rgb(143, 93, 46))
        drawText(canvas, "Novo destino desbloqueado", rect.left + 36f, rect.top + 56f, 30f, Color.rgb(59, 36, 18), Paint.Align.LEFT)
        val start = Vec(rect.left + rect.width() * 0.28f, rect.top + rect.height() * 0.58f)
        val finish = Vec(rect.left + rect.width() * 0.72f, rect.top + rect.height() * 0.42f)
        paint.color = Color.rgb(181, 83, 39)
        paint.strokeWidth = 8f
        canvas.drawLine(start.x, start.y, finish.x, finish.y, paint)
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(196, 61, 50)
        canvas.drawCircle(finish.x, finish.y, 18f, paint)
        drawText(canvas, "Picos", start.x, start.y + 46f, 22f, Color.rgb(59, 36, 18), Paint.Align.CENTER)
        drawText(canvas, "São José do Piauí - Capadócia Nordestina", finish.x, finish.y + 68f, 20f, Color.rgb(59, 36, 18), Paint.Align.CENTER)
        drawText(canvas, "Toque no mapa para ver a próxima jornada.", rect.centerX(), rect.bottom - 34f, 20f, Color.rgb(59, 36, 18), Paint.Align.CENTER)
    }

    private fun drawCapadocia(canvas: Canvas) {
        paint.color = Color.BLACK
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        assets.capadocia?.let { drawCover(canvas, it, RectF(0f, 0f, width.toFloat(), height.toFloat())) }
        drawText(canvas, "Clique para voltar ao mapa de Picos", width / 2f, height - 42f, 24f, Color.rgb(255, 243, 199), Paint.Align.CENTER)
    }

    private fun handlePanelTap(point: Vec) {
        uiButtons.firstOrNull { it.first.contains(point.x, point.y) }?.second?.invoke()
        if (panel == Panel.TRAVEL_MAP) panel = Panel.CAPADOCIA else if (panel == Panel.CAPADOCIA) panel = Panel.NONE
    }

    private fun drawClose(canvas: Canvas, rect: RectF) {
        val close = RectF(rect.right - 96f, rect.top + 14f, rect.right - 20f, rect.top + 52f)
        drawGoldButton(canvas, close, "Fechar")
        uiButtons.add(close to { panel = Panel.NONE; if (screen == Screen.PLAY && !running) screen = Screen.MENU })
    }

    private fun drawDialog(canvas: Canvas, d: DialogState) {
        val rect = RectF(24f, height - min(310f, height * 0.55f), width - 24f, height - 18f)
        drawPanelRect(canvas, rect, Color.argb(242, 46, 23, 11), Color.rgb(255, 194, 71))
        drawText(canvas, d.title, rect.left + 18f, rect.top + 34f, 21f, Color.rgb(255, 194, 71), Paint.Align.LEFT)
        drawMultiline(canvas, d.text, rect.left + 18f, rect.top + 62f, rect.width() - 36f, 18f, Color.rgb(255, 247, 220))
        dialogButtonRects(d).forEach { (r, choice) ->
            drawGoldButton(canvas, r, choice.text)
        }
    }

    private fun dialogButtonRects(d: DialogState): List<Pair<RectF, Choice>> {
        val rect = RectF(24f, height - min(310f, height * 0.55f), width - 24f, height - 18f)
        val buttonH = if (d.choices.size > 2) 42f else 48f
        return d.choices.mapIndexed { index, choice ->
            RectF(rect.left + 18f, rect.bottom - 18f - (d.choices.size - index) * (buttonH + 8f), rect.right - 18f, rect.bottom - 18f - (d.choices.size - index - 1) * (buttonH + 8f) - 8f) to choice
        }
    }

    private fun drawGoldButton(canvas: Canvas, rect: RectF, text: String) {
        drawPanelRect(canvas, rect, Color.rgb(255, 194, 71), Color.rgb(107, 61, 33), 8f)
        drawText(canvas, text, rect.centerX(), rect.centerY() + 7f, if (text.length > 44) 13f else 16f, Color.rgb(36, 19, 6), Paint.Align.CENTER, rect.width() - 14f)
    }

    private fun drawPanelRect(canvas: Canvas, rect: RectF, fill: Int, stroke: Int, radius: Float = 8f) {
        paint.style = Paint.Style.FILL
        paint.color = fill
        canvas.drawRoundRect(rect, radius, radius, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 3f
        paint.color = stroke
        canvas.drawRoundRect(rect, radius, radius, paint)
        paint.style = Paint.Style.FILL
    }

    private fun drawText(canvas: Canvas, text: String, x: Float, y: Float, size: Float, color: Int, align: Paint.Align, maxWidth: Float = Float.MAX_VALUE) {
        textPaint.textSize = size
        textPaint.color = color
        textPaint.textAlign = align
        val output = if (textPaint.measureText(text) > maxWidth) ellipsize(text, maxWidth) else text
        canvas.drawText(output, x, y, textPaint)
    }

    private fun drawMultiline(canvas: Canvas, text: String, x: Float, y: Float, maxWidth: Float, size: Float, color: Int) {
        textPaint.textSize = size
        textPaint.color = color
        textPaint.textAlign = Paint.Align.LEFT
        var cy = y
        text.split("\n").flatMap { wrapText(it, maxWidth) }.forEach { line ->
            canvas.drawText(line, x, cy, textPaint)
            cy += size + 7f
        }
    }

    private fun wrapText(text: String, maxWidth: Float): List<String> {
        val lines = mutableListOf<String>()
        var line = ""
        text.split(" ").forEach { word ->
            val next = if (line.isEmpty()) word else "$line $word"
            if (textPaint.measureText(next) <= maxWidth) line = next else {
                if (line.isNotEmpty()) lines.add(line)
                line = word
            }
        }
        if (line.isNotEmpty()) lines.add(line)
        return lines
    }

    private fun ellipsize(text: String, maxWidth: Float): String {
        var out = text
        while (out.length > 3 && textPaint.measureText("$out...") > maxWidth) out = out.dropLast(1)
        return "$out..."
    }

    private fun drawCover(canvas: Canvas, bitmap: Bitmap, rect: RectF) {
        val scale = max(rect.width() / bitmap.width, rect.height() / bitmap.height)
        val dw = bitmap.width * scale
        val dh = bitmap.height * scale
        val dst = RectF(rect.centerX() - dw / 2f, rect.centerY() - dh / 2f, rect.centerX() + dw / 2f, rect.centerY() + dh / 2f)
        canvas.drawBitmap(bitmap, null, dst, null)
    }

    private fun drawMoto(canvas: Canvas, pos: Vec) {
        assets.moto?.let { canvas.drawBitmap(it, null, RectF(pos.x - 90f, pos.y - 70f, pos.x + 90f, pos.y + 35f), null) }
            ?: drawNpc(canvas, pos.x, pos.y)
    }

    private fun drawNpc(canvas: Canvas, x: Float, y: Float) {
        paint.color = Color.rgb(242, 209, 122)
        canvas.drawRect(x - 12f, y - 34f, x + 12f, y - 20f, paint)
        paint.color = Color.rgb(163, 62, 62)
        canvas.drawRect(x - 14f, y - 20f, x + 14f, y + 12f, paint)
    }

    private fun drawPropBitmap(canvas: Canvas, bitmap: Bitmap?, x: Float, y: Float, drawH: Float) {
        if (bitmap == null) return
        paint.color = Color.argb(42, 0, 0, 0)
        canvas.drawOval(RectF(x - 28f, y + 16f, x + 28f, y + 25f), paint)
        val drawW = drawH * bitmap.width / bitmap.height
        canvas.drawBitmap(bitmap, null, RectF(x - drawW / 2f, y - drawH + 18f, x + drawW / 2f, y + 18f), null)
    }

    private fun drawLandmarkFallback(canvas: Canvas, x: Float, y: Float) {
        paint.color = Color.rgb(215, 200, 165)
        canvas.drawPath(Path().apply {
            moveTo(x - 72f, y - 18f)
            lineTo(x, y - 96f)
            lineTo(x + 72f, y - 18f)
            close()
        }, paint)
        paint.color = Color.rgb(120, 68, 44)
        canvas.drawRect(x - 58f, y - 18f, x + 58f, y + 42f, paint)
    }

    private fun drawLamp(canvas: Canvas, x: Float, y: Float) {
        paint.color = Color.rgb(45, 49, 54)
        canvas.drawRect(x + 22f, y + 12f, x + 26f, y + 44f, paint)
        paint.color = Color.rgb(255, 232, 163)
        canvas.drawCircle(x + 24f, y + 10f, 8f, paint)
    }

    private fun drawBench(canvas: Canvas, x: Float, y: Float) {
        paint.color = Color.rgb(125, 81, 53)
        canvas.drawRect(x + 8f, y + 24f, x + 40f, y + 31f, paint)
        canvas.drawRect(x + 9f, y + 16f, x + 39f, y + 22f, paint)
    }

    private fun buildWorld() {
        for (x in 0 until WORLD_W) {
            addSolid(x, WORLD_TOP_TILE)
            addSolid(x, WORLD_H - 1)
        }
        for (y in WORLD_TOP_TILE until WORLD_H) {
            addSolid(0, y)
            addSolid(WORLD_W - 1, y)
        }
        for (x in 28 until WORLD_W - 1) for (y in 6..26) picosTiles.add(key(x, y))
        for (x in ozildoPlaza.left until ozildoPlaza.right) for (y in ozildoPlaza.top until ozildoPlaza.bottom) plazaTiles.add(key(x, y))
        for (x in churchPlaza.left until churchPlaza.right) for (y in churchPlaza.top until churchPlaza.bottom) plazaTiles.add(key(x, y))
        props.add(Prop("church", picosChurch.first, picosChurch.second))
        props.add(Prop("museum", ozildoMuseum.first, ozildoMuseum.second))
        props.add(Prop("feira_roupas", picosChurch.first + 5, -4))
        props.add(Prop("feira_bancas", picosChurch.first + 5, 2))
        props.add(Prop("feira_vertical", picosChurch.first + 26, -5))
        props.add(Prop("dona", donaRita.first, donaRita.second))
        props.add(Prop("ana", anaMuseu.first, anaMuseu.second))
        props.add(Prop("seu_ze", picosChurch.first + 3, picosChurch.second + 2))
        props.add(Prop("sign", 13, 6))
        listOf(Pair(35, 15), Pair(45, 15), Pair(56, 16), Pair(66, 12), Pair(74, 21)).forEach { props.add(Prop("lamp", it.first, it.second)) }
        listOf(Pair(31, 20), Pair(42, 21), Pair(53, 20), Pair(70, 19)).forEach { props.add(Prop("bench", it.first, it.second)) }
        listOf(
            Prop("aroeira", 26, 21), Prop("buriti", 32, 23), Prop("malungu", 58, 6),
            Prop("manga", 62, 22), Prop("manga_diferente", 76, 7), Prop("umbu", 81, 22),
            Prop("ype", 44, 6), Prop("cactus", 29, 24), Prop("cactus", 83, 24)
        ).forEach { props.add(it) }
        solidRects.add(RectF(picosChurch.first * TILE - 168f, picosChurch.second * TILE - 255f, picosChurch.first * TILE + 278f, picosChurch.second * TILE + 80f))
        solidRects.add(RectF(ozildoMuseum.first * TILE - 170f, ozildoMuseum.second * TILE - 170f, ozildoMuseum.first * TILE + 450f, ozildoMuseum.second * TILE + 210f))
        solidRects.add(RectF((picosChurch.first + 5) * TILE, -4f * TILE + 28f, (picosChurch.first + 5) * TILE + 900f, -4f * TILE + 272f))
        solidRects.add(RectF((picosChurch.first + 5) * TILE, 2f * TILE + 28f, (picosChurch.first + 5) * TILE + 805f, 2f * TILE + 228f))
        solidRects.add(RectF((picosChurch.first + 26) * TILE - 106f, -5f * TILE - 12f, (picosChurch.first + 26) * TILE + 154f, -5f * TILE + 370f))
        missions.add(Mission(PAGE_FEIRA_ID, "Página na Feira Livre", "Diário das Raízes", "Página da Feira Livre", "A Feira Livre de Picos guarda encontros, trabalho e sabores que ajudam a contar a economia e a vida cotidiana da cidade.", donaRita.first + 1, donaRita.second + 1, "diary_page", PAGE_FEIRA_RELEASED_ID))
        missions.add(Mission(PAGE_MUSEU_ID, "Página no Museu Ozildo Albano", "Diário das Raízes", "Página do Museu", "O Museu Ozildo Albano preserva memórias, objetos e registros que ajudam a cidade a reconhecer sua própria história.", anaMuseu.first + 1, anaMuseu.second + 1, "diary_page", PAGE_MUSEU_RELEASED_ID))
        for (x in 26..28) for (y in 18..22) solids.remove(key(x, y))
    }

    private fun addSolid(x: Int, y: Int) {
        solids.add(key(x, y))
    }

    private fun saveProgress() {
        prefs.edit()
            .putStringSet("learned", learned)
            .putStringSet("redeemed", redeemed)
            .apply()
    }

    private fun loadProgress() {
        learned.addAll(prefs.getStringSet("learned", emptySet()) ?: emptySet())
        redeemed.addAll(prefs.getStringSet("redeemed", emptySet()) ?: emptySet())
    }

    private fun saveSettings() {
        prefs.edit()
            .putString("character", selectedCharacter)
            .putFloat("music_volume", musicVolume)
            .putFloat("sfx_volume", sfxVolume)
            .apply()
    }

    private fun setupAudio() {
        runCatching {
            val afd = context.assets.openFd("www/godot/assets/audio_abertura_picos.mp3")
            mediaPlayer = MediaPlayer().apply {
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                isLooping = true
                prepare()
                setVolume(musicVolume / 100f, musicVolume / 100f)
            }
        }
        soundPool = SoundPool.Builder()
            .setMaxStreams(2)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            .build()
    }

    private fun playCameraSound() {
        soundPool?.let { pool ->
            if (cameraSoundId != 0) pool.play(cameraSoundId, sfxVolume / 100f, sfxVolume / 100f, 1, 0, 1f)
        }
    }

    private fun key(x: Int, y: Int) = "$x,$y"
    private fun near(a: Vec, b: Vec, radius: Float) = distance(a, b) < radius
    private fun distance(a: Vec, b: Vec) = hypot(a.x - b.x, a.y - b.y)
    private fun learnedCount() = missions.count { learned.contains(it.id) } + if (learned.contains(OPENING_MISSION_ID)) 1 else 0
    private fun dpadRect() = RectF(24f, height - 168f, 168f, height - 24f)
    private fun modalRect() = RectF(max(18f, width * 0.12f), max(18f, height * 0.1f), min(width - 18f, width * 0.88f), min(height - 18f, height * 0.9f))
    private fun openingCameraPos() = Vec(682f, 1132f)
    private fun openingMotoPos() = Vec(1360f, 1268f)
    private fun seuZePos() = Vec(picosChurch.first * TILE + 140f, picosChurch.second * TILE + 132f)
    private fun churchPlazaSpawn() = Vec(picosChurch.first * TILE + 90f, picosChurch.second * TILE + 220f)
    private fun churchPhotoPos() = Vec(picosChurch.first * TILE + 54f, picosChurch.second * TILE + 236f)
    private fun fairPhotoPos() = Vec(donaRita.first * TILE - 92f, donaRita.second * TILE + 74f)
    private fun museumPhotoPos() = Vec(anaMuseu.first * TILE - 84f, anaMuseu.second * TILE + 70f)

    private inner class Assets {
        var menu: Bitmap? = null
        var buttonPlay: Bitmap? = null
        var buttonOptions: Bitmap? = null
        var buttonMarket: Bitmap? = null
        var playerMale: Bitmap? = null
        var playerFemale: Bitmap? = null
        var church: Bitmap? = null
        var museum: Bitmap? = null
        var sign: Bitmap? = null
        var camera: Bitmap? = null
        var moto: Bitmap? = null
        var dirt: Bitmap? = null
        var grass: Bitmap? = null
        var asphalt: Bitmap? = null
        var ozildoPhoto: Bitmap? = null
        var cactus: Bitmap? = null
        var seuZe: Bitmap? = null
        var feiraAdaptada: Bitmap? = null
        var feiraRoupas: Bitmap? = null
        var feiraBancas: Bitmap? = null
        var donaRita: Bitmap? = null
        var ana: Bitmap? = null
        var paper: Bitmap? = null
        var memoryPolaroid: Bitmap? = null
        var churchMemory: Bitmap? = null
        var fairMemory: Bitmap? = null
        var museumMemory: Bitmap? = null
        var churchPlaza: Bitmap? = null
        var museumPlaza: Bitmap? = null
        var capadocia: Bitmap? = null
        val trees = mutableMapOf<String, Bitmap?>()

        fun load() {
            menu = bitmap("www/elementos/menu_inicial_limpa.png")
            buttonPlay = bitmap("www/elementos/botoes/botao_jogar.png")
            buttonOptions = bitmap("www/elementos/botoes/botao_opcoes.png")
            buttonMarket = bitmap("www/elementos/botoes/botao_marketplace.png")
            playerMale = bitmap("www/godot/assets/personagem_masculino.png") ?: bitmap("www/elementos/personagem_animacoes.jpeg")
            playerFemale = bitmap("www/godot/assets/personagem_feminina.png")
            church = bitmap("www/godot/assets/igreja_picos.png")
            museum = bitmap("www/godot/assets/museu_picos.png")
            sign = bitmap("www/godot/assets/placa_picos.png")
            camera = bitmap("www/godot/assets/camera.png")
            moto = bitmap("www/godot/assets/opening_market_mototaxi.png")
            dirt = bitmap("www/godot/assets/terra_dinamica.png")
            grass = bitmap("www/godot/assets/opening_grass_tile.png")
            asphalt = bitmap("www/godot/assets/asfalto.png")
            ozildoPhoto = bitmap("www/godot/assets/praca_ozildo_albano.jpeg")
            cactus = bitmap("www/godot/assets/cacto_pixel.png")
            seuZe = bitmap("www/godot/assets/seu_ze_lendas.png")
            feiraAdaptada = bitmap("www/godot/assets/feira_adaptada.png")
            feiraRoupas = bitmap("www/godot/assets/feira_roupas_horizontal.png")
            feiraBancas = bitmap("www/godot/assets/feira_bancas_horizontal.png")
            donaRita = bitmap("www/godot/assets/dona_rita_sheet.png")
            ana = bitmap("www/godot/assets/ana_sheet.png")
            paper = bitmap("www/godot/assets/papel_elemento.png")
            memoryPolaroid = bitmap("www/godot/assets/memoria_picos_polaroid.png")
            churchMemory = bitmap("www/godot/assets/memoria_igreja_matriz.png")
            fairMemory = bitmap("www/godot/assets/memoria_feira_livre.png")
            museumMemory = bitmap("www/godot/assets/memoria_museu_ozildo.png")
            churchPlaza = bitmap("www/godot/assets/praca_igreja_picos_hd.png")
            museumPlaza = bitmap("www/godot/assets/praca_museu_completa.png")
            capadocia = bitmap("www/godot/assets/capadocia_em_breve.png")
            trees["aroeira"] = bitmap("www/godot/assets/aroeira.png")
            trees["buriti"] = bitmap("www/godot/assets/buriti.png")
            trees["malungu"] = bitmap("www/godot/assets/malungu.png")
            trees["manga"] = bitmap("www/godot/assets/manga.png")
            trees["manga_diferente"] = bitmap("www/godot/assets/manga-diferente.png")
            trees["umbu"] = bitmap("www/godot/assets/umbu.png")
            trees["ype"] = bitmap("www/godot/assets/ype.png")
        }

        private fun bitmap(path: String): Bitmap? = runCatching {
            context.assets.open(path).use { BitmapFactory.decodeStream(it) }
        }.getOrNull()
    }

    private data class Quiz(val question: String, val options: List<String>, val answer: Int, val success: String)
}
