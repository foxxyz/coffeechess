em_value = 64

class Chess
	@players = ['white', 'black']
	
	# Set up board	
	constructor: (@board) ->
		@moves = []
		@en_passant = false
		@promotion = false
		@active = false
		@player = null
		@board = for x in [0..7]
			for y in [0..7]
				null

	# Add piece to board
	add: (piece) ->
		@board[piece.x][piece.y] = piece

	draw: ->
		$("#" + @player).addClass("active").siblings().removeClass("active")

	invalid: (position) ->
		position.x < 0 or position.y < 0 or position.x >= @board.length or position.y >= @board.length

	next_turn: ->
		@player = if @player == 'white' then 'black' else 'white'
		@draw()

	# Get piece by position
	piece: (position) ->
		# Check en_passant register for additional placement
		if @en_passant and @en_passant.position.x == position.x and @en_passant.position.y == position.y
			return @en_passant.piece
		@board[position.x][position.y]

	promote: (pawn) ->
		$(".promotion").show()
		$(".promotion span").on "click", ->
			pawn.promote(pieces[$(this).attr("class")])
			$(this).parent().fadeOut()

	record: (piece, new_position) ->
		@moves.push [piece, {x: piece.x, y: piece.y}, new_position]

	# Remove piece from board
	remove: (piece) ->
		@board[piece.x][piece.y] = null

	start: ->
		@active = true
		@next_turn()

	under_attack: (position) ->
		false


class Piece
	constructor: (@dom_object, @color, position, @parent) ->
		if position
			@x = position.x
			@y = position.y
		else
			@get_position(@dom_object)
		@direction = if @color == 'black' then 1 else -1
		if @parent and @dom_object
			@dom_object.on "click", $.proxy(@parent.make_move, @parent, position)
		else if @dom_object
			@dom_object.on("click", $.proxy(this.select, this))
		@touched = false

	class: ->
		@constructor.name.toLowerCase()

	deselect: ->
		$('#pieces span').removeClass "selected"
		$("#possible_moves").empty()
		game.next_turn()

	draw: (fluid) ->
		if fluid
			@dom_object.animate(left: @x + "em", top: @y + "em")
		else
			@dom_object.css(left: @x + "em", top: @y + "em")

	get_position: (dom_object) ->
		unless @dom_object.css("left").indexOf("em") is -1
			@x = Math.round @dom_object.css("left").replace(/em/, "")
			@y = Math.round @dom_object.css("top").replace(/em/, "")
		else
			@x = Math.round @dom_object.css("left").replace(/px/, "") / em_value
			@y = Math.round @dom_object.css("top").replace(/px/, "") / em_value
		@draw()

	html: ->
		@constructor.html_code

	make_move: (position) ->
		@move(position)
		@deselect()

	move: (position) ->
		game.remove(this)
		game.record(this, position)
		[@x, @y] = [position.x, position.y]	
		if position.capture
			captured = game.piece(position)
			captured.dom_object.fadeOut()
			game.remove(captured)
		if position.castle
			rook_position = {x: 4 + ((4 - position.x) / -2), y: position.y}
			position.castle.move(rook_position)
		game.en_passant = if position.en_passant then {piece: this, position: position.en_passant} else false
		game.add(this)
		@touched = true
		@draw(true)
		@post_move()
		game.draw()

	position: ->
		return {x: @x, y: @y}

	possible_moves: ->
		moves = []
		for pos in @constructor.move_matrix
			for n in [1..@constructor.range]
				position = {x: @x + pos[0] * n, y: @y + pos[1] * n}
				break if game.invalid(position)
				if game.piece(position)
					if game.piece(position).color != @color
						position.capture = true
						moves.push position
					break
				moves.push position
		moves

	post_move: ->

	select: ->
		return if @color != game.player or not game.active
		$('#pieces span').removeClass "selected"
		@dom_object.addClass "selected"
		$("#possible_moves").empty()
		for move in this.possible_moves()
			ghost_dom = @dom_object.clone().removeClass()
			ghost = new @constructor(ghost_dom, @color, move, this)
			ghost.draw()
			ghost_dom.text("").addClass("capture") if move.capture
			$("#possible_moves").append ghost_dom


class Pawn extends Piece
	@html_code = "&#9823"

	possible_moves: ->
		moves = []
		move_matrix = [[0, @direction]]
		capture_matrix = [[-1, @direction], [1, @direction]]
		if @y == 3.5 - 2.5 * @direction
			move_matrix.push [0, @direction * 2]
		for pos in move_matrix
			position = {x: @x + pos[0], y: @y + pos[1]}
			if Math.abs(pos[1]) == 2
				position.en_passant = {x: @x, y: @y + pos[1] / 2, 'capture': true}
			break if game.invalid(position) or game.piece(position)
			moves.push position
		for pos in capture_matrix
			position = {x: @x + pos[0], y: @y + pos[1], capture: true}
			continue if game.invalid(position)
			continue unless game.piece(position) and game.piece(position).color != @color
			moves.push position
		moves

	# Activate promotions
	post_move: ->
		if @y != 3.5 + 3.5 * @direction
			return
		game.promote(this)
		game.active = false

	promote: (piece) ->
		pawn = this
		@dom_object.fadeOut ->
			game.remove(pawn)
			promoted = new piece(pawn.dom_object, pawn.color)
			game.add(promoted)
			console.log(promoted)
			console.log(promoted.html())
			promoted.dom_object.removeClass().addClass(promoted.class()).html(promoted.html()).fadeIn()
			game.active = true

class Bishop extends Piece
	@move_matrix = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
	@range = 8
	@html_code = "&#9821"


class Knight extends Piece
	@move_matrix = [[1, 2], [2, 1], [-1, 2], [-2, 1], [1, -2], [2, -1], [-1, -2], [-2, -1]]
	@range = 1
	@html_code = "&#9822"


class Rook extends Piece
	@move_matrix = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	@range = 8
	@html_code = "&#9820"


class King extends Piece
	@move_matrix = [[-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1], [1, 0], [1, -1], [0, -1]]
	@range = 1
	@html_code = "&#9818"

	possible_moves: ->
		moves = super
		if @touched
			return moves
		# Add castling moves
		for rook_x in [7, 0]
			rook = game.piece({x: rook_x, y: @y})
			range = if rook_x is 7 then [5..6] else [1..3]
			obstacles = (game.piece({x: x, y: @y}) for x in range when game.piece({x: x, y: @y}) or game.under_attack({x: x, y: @y}))
			if not obstacles.length and not rook.touched
				moves.push {x: range[1], y: @y, castle: rook}
		moves


class Queen extends Piece
	@move_matrix = [[-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1], [1, 0], [1, -1], [0, -1]]
	@range = 8
	@html_code = "&#9819"


game = new Chess
pieces = {'pawn': Pawn, 'bishop': Bishop, 'knight': Knight, 'rook': Rook, 'queen': Queen, 'king': King}
orientation = {x: 55, y: -7, z: 21}
current_orientation = {x: 0, y:0, z:0}

$ ->
	# Add some space for possible moves
	game_dom = $("#game")
	game_dom.append "<div id=\"possible_moves\"></div>" unless $("#possible_moves").length

	# Initialize the pieces
	$("#pieces span").each ->
		piece = new pieces[$(this).attr "class"]($(this), $(this).parent().attr('id'))
		game.add(piece)

	# Start game
	game.start()

	# 3D Rotation
	drag_start = null
	game_dom.on "mousedown", (e) ->
		drag_start = [e.pageX, e.pageY]

	$(document).on "mousemove", (e) ->
		return if not drag_start
		offset = [e.pageX - drag_start[0], e.pageY - drag_start[1]]
		current_orientation = {'x': (orientation.x - offset[1]) % 360, 'y': (orientation.y + offset[0]) % 360, 'z': orientation.z}
		game_dom.css({'-webkit-transform': 'rotateX(' + current_orientation.x + 'deg) rotateZ(' + current_orientation.z + 'deg) rotateY(' + current_orientation.y + 'deg)'})

	.on "mouseup", ->
		drag_start = null
		orientation = current_orientation
