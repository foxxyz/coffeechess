em_value = 64


class Player

	constructor: (@game, @color) ->
		@dom_object = $("#" + @color)

	draw: ->
		if @game.player.color == @color
			@dom_object.addClass("active").siblings().removeClass("active")

	make_move: ->

class HumanPlayer extends Player

	make_move: ->
		


class AIPlayer extends Player

	auto_move: ->
		pieces = @dom_object.children(':not(:animated)')
		moves = $("#possible_moves")
		# Select random piece
		until moves.children().length
			pieces.eq(Math.floor(Math.random() * pieces.length)).trigger('click')
		# Select random possible move
		moves = moves.children()
		moves.eq(Math.floor(Math.random() * moves.length)).trigger('click')

	make_move: ->
		if @game.promotion
			$("#promotion span").eq(Math.floor(Math.random() * 4)).trigger('click')
		else
			setTimeout =>
				@auto_move()
			, 500


window.Chess = class Chess
	
	# Set up board	
	constructor: (@dom, @board) ->
		@moves = []
		@en_passant = false
		@promotion = false
		@active = false
		@player = null
		@in_check = false
		@board = @set_up(@board)
		@players = {'white': new AIPlayer(this, 'white'), 'black': new AIPlayer(this, 'black')}
		
	# Add piece to board
	add: (piece) ->
		@board[piece.x][piece.y] = piece

	# Search for checks
	check_exists: (with_piece, at_position) ->
		in_check = []

		# Switch out piece temporarily
		if with_piece? and at_position?
			piece_at_new_position = @board[at_position.x][at_position.y]
			@remove(with_piece)
			current_position = {x: with_piece.x, y: with_piece.y}
			[with_piece.x, with_piece.y] = [at_position.x, at_position.y]
			@add(with_piece)

		# Check if a king is under attack
		for piece in @pieces()
			for position in piece.possible_moves(false)
				under_attack = @piece(position)
				if under_attack instanceof King
					in_check.push(under_attack.color)

		# Put piece back into current position
		if with_piece? and at_position?
			[with_piece.x, with_piece.y] = [current_position.x, current_position.y]
			@board[at_position.x][at_position.y] = piece_at_new_position
			@add(with_piece)

		in_check

	draw: ->
		for color, player of @players
			player.draw()
		if @in_check.length then game.dom.addClass("in_check") else game.dom.removeClass("in_check")
		if @in_check.length and not @active then game.dom.addClass("mate")

	invalid: (position) ->
		position.x < 0 or position.y < 0 or position.x >= @board.length or position.y >= @board.length

	next_turn: ->
		@player = if @player and @player.color == 'white' then @players.black else @players.white
		@in_check = @check_exists()
		if @in_check.length
			active_pieces = (piece for piece in @pieces() when piece.possible_moves().length > 0 and piece.color in @in_check)
			@active = active_pieces.length != 0
		@draw()
		@player.make_move()

	# Get piece by position
	piece: (position) ->
		# Check en_passant register for additional placement
		if @en_passant and @en_passant.position.x == position.x and @en_passant.position.y == position.y
			return @en_passant.piece
		@board[position.x][position.y]

	# Get all the pieces
	pieces: ->
		pieces = []
		for col in @board
			for square in col
				pieces.push(square) if square
		pieces

	promote: (pawn) ->
		$(".promotion").show()
		$(".promotion span").on "click", ->
			pawn.promote(pieces[$(this).attr("class")])
			$(this).parent().fadeOut(-> @remove())

	record: (piece, new_position) ->
		console.log(piece.class() + " from " + piece.x + "," + piece.y + " to " + new_position.x + "," + new_position.y)
		@moves.push [piece, {x: piece.x, y: piece.y}, new_position]

	# Remove piece from board
	remove: (piece) ->
		@board[piece.x][piece.y] = null

	set_up: (fen_string) ->
		board = for x in [0..7]
			for y in [0..7]
				null
		if not fen_string?
			return board
		[board_string, player] = fen_string.split " "
		[x, y] = [0, 0]
		for char in board_string
			piece = null
			switch char.toLowerCase()
				when "b" then piece = Bishop
				when "k" then piece = King
				when "n" then piece = Knight
				when "p" then piece = Pawn
				when "q" then piece = Queen
				when "r" then piece = Rook
				when "/"
					y += 1
					x = 0
				else x += parseInt(char)
			if not piece?
				continue
			color = if char.charCodeAt() < 90 then "black" else "white"
			board[x][y] = new piece($(""), this, color, {"x": x, "y": y})
			x += 1
		@player = if player == "w" then @players.white else @players.black
		board

	start: ->
		@active = true
		@next_turn()

	under_attack: (position) ->
		false


class Piece
	constructor: (@dom_object, @game, @color, position, @parent) ->
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
		@game.next_turn()

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
		@game.remove(this)
		@game.record(this, position)
		[@x, @y] = [position.x, position.y]	
		if position.capture
			captured = @game.piece(position)
			captured.dom_object.fadeOut(-> @remove())
			@game.remove(captured)
		if position.castle
			rook_position = {x: 4 + ((4 - position.x) / -2), y: position.y}
			position.castle.move(rook_position)
		@game.en_passant = if position.en_passant then {piece: this, position: position.en_passant} else false
		@game.add(this)
		@touched = true
		@draw(true)
		@post_move()
		@game.draw()

	position: ->
		return {x: @x, y: @y}

	possible_moves: (filter_checks=true) ->
		moves = []
		for pos in @constructor.move_matrix
			for n in [1..@constructor.range]
				position = {x: @x + pos[0] * n, y: @y + pos[1] * n}
				break if @game.invalid(position) 
				if @game.piece(position)
					if @game.piece(position).color != @color
						position.capture = true
						moves.push position
					break
				moves.push position

		# Ignore moves that would keep the game in check
		if filter_checks
			moves = (move for move in moves when @color not in @game.check_exists(this, move))
			
		moves

	post_move: ->

	select: ->
		return if @color != @game.player.color or not @game.active
		$('#pieces span').removeClass "selected"
		@dom_object.addClass "selected"
		$("#possible_moves").empty()
		for move in this.possible_moves()
			ghost_dom = @dom_object.clone().removeClass()
			ghost = new @constructor(ghost_dom, @game, @color, move, this)
			ghost.draw()
			ghost_dom.text("").addClass("capture") if move.capture
			$("#possible_moves").append ghost_dom


class Pawn extends Piece
	@html_code = "&#9823"

	possible_moves: (filter_checks=true) ->
		moves = []
		move_matrix = [[0, @direction]]
		capture_matrix = [[-1, @direction], [1, @direction]]
		if @y == 3.5 - 2.5 * @direction
			move_matrix.push [0, @direction * 2]
		for pos in move_matrix
			position = {x: @x + pos[0], y: @y + pos[1]}
			if Math.abs(pos[1]) == 2
				position.en_passant = {x: @x, y: @y + pos[1] / 2, 'capture': true}
			break if @game.invalid(position) or @game.piece(position)
			moves.push position
		for pos in capture_matrix
			position = {x: @x + pos[0], y: @y + pos[1], capture: true}
			continue if @game.invalid(position)
			continue unless @game.piece(position) and @game.piece(position).color != @color
			moves.push position

		# Ignore moves that would keep the game in check
		if filter_checks
			moves = (move for move in moves when @color not in @game.check_exists(this, move))

		moves

	# Activate promotions
	post_move: ->
		if @y != 3.5 + 3.5 * @direction
			return
		@game.promote(this)
		@game.active = false

	promote: (piece) ->
		@dom_object.fadeOut =>
			@game.remove(this)
			promoted = new piece(@dom_object, @game, @color)
			@game.add(promoted)
			promoted.dom_object.removeClass().addClass(promoted.class()).html(promoted.html()).fadeIn()
			@game.active = true

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
			rook = @game.piece({x: rook_x, y: @y})
			continue if not rook
			range = if rook_x is 7 then [5..6] else [1..3]
			obstacles = (@game.piece({x: x, y: @y}) for x in range when @game.piece({x: x, y: @y}) or @game.under_attack({x: x, y: @y}))
			if not obstacles.length and not rook.touched
				moves.push {x: range[1], y: @y, castle: rook}
		moves


class Queen extends Piece
	@move_matrix = [[-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1], [1, 0], [1, -1], [0, -1]]
	@range = 8
	@html_code = "&#9819"


game = null
pieces = {'pawn': Pawn, 'bishop': Bishop, 'knight': Knight, 'rook': Rook, 'queen': Queen, 'king': King}
orientation = current_orientation = {x: 0, y: 0, z: 0}

$ ->

	game = new Chess($("#game"))

	# Add some space for possible moves
	game.dom.append "<div id=\"possible_moves\"></div>" unless $("#possible_moves").length

	# Initialize the pieces
	$("#pieces span").each ->
		piece = new pieces[$(this).attr "class"]($(this), game, $(this).parent().attr('id'))
		game.add(piece)

	# Start game
	game.start()

	# 3D Rotation
	drag_start = null
	game.dom.on "mousedown", (e) ->
		drag_start = [e.pageX, e.pageY]

	$(document).on "mousemove", (e) ->
		return if not drag_start
		offset = [e.pageX - drag_start[0], e.pageY - drag_start[1]]
		current_orientation = {'x': (orientation.x - offset[1]) % 360, 'y': (orientation.y + offset[0]) % 360, 'z': orientation.z}
		if Math.abs(current_orientation.x) > 50 and Math.abs(current_orientation.x) < 310 then $("#pieces span, #possible_moves").addClass("upright") else $("#pieces span, #possible_moves").removeClass("upright")
		game.dom.css({'-webkit-transform': 'rotateX(' + current_orientation.x + 'deg) rotateZ(' + current_orientation.z + 'deg) rotateY(' + current_orientation.y + 'deg)'})

	.on "mouseup", ->
		drag_start = null
		orientation = current_orientation
