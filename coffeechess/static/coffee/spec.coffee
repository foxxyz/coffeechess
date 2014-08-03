# Tests for some more advanced chess features

describe "chess", ->

	it "handles FEN board notation", ->
		board = "RNrn4/8/8/P7/7Q/6q1/3b4/K6k b"
		game = new Chess($(""), board)
		expect(game.board[0][0].class()).toBe "rook"
		expect(game.board[0][0].color).toBe "black"
		expect(game.board[1][0].class()).toBe "knight"
		expect(game.board[1][0].color).toBe "black"
		expect(game.board[2][0].class()).toBe "rook"
		expect(game.board[2][0].color).toBe "white"
		expect(game.board[3][0].class()).toBe "knight"
		expect(game.board[3][0].color).toBe "white"
		expect(game.board[4][0]).toBe null
		expect(game.board[0][3].class()).toBe "pawn"
		expect(game.board[0][3].color).toBe "black"
		expect(game.board[7][4].class()).toBe "queen"
		expect(game.board[7][4].color).toBe "black"
		expect(game.board[6][5].class()).toBe "queen"
		expect(game.board[6][5].color).toBe "white"
		expect(game.board[3][6].class()).toBe "bishop"
		expect(game.board[3][6].color).toBe "white"
		expect(game.board[0][7].class()).toBe "king"
		expect(game.board[0][7].color).toBe "black"
		expect(game.board[7][7].class()).toBe "king"
		expect(game.board[7][7].color).toBe "white"
		expect(game.player).toBe "black"

	it "handles en passant capture", ->
		board = "8/PPPPPPPP/8/5p2 b"
		game = new Chess($(""), board)
		pawn = game.board[6][1]
		for move in pawn.possible_moves()
			game.board[6][1].make_move(move) if move.x == 6 and move.y == 3
		expect(game.board[5][3].possible_moves()).toContain {x: 6, y: 2, capture: true}

	it "does not allow moves that would put the player in check", ->
		board = "8/PPPPPPPP/8/5k2 w"
		game = new Chess($(""), board)
		expect(game.board[5][3].possible_moves()).toContain {x: 6, y: 3}
		expect(game.board[5][3].possible_moves()).not.toContain {x: 6, y: 2}

	it "does not allow moves that would keep the player in check", ->
		board = "8/PPPPPPPP/4k3/8/8/4q3 w"
		game = new Chess($(""), board)
		expect(game.board[4][2].possible_moves()).toContain {x: 4, y: 1, capture: true}
		expect(game.board[4][2].possible_moves()).not.toContain {x: 5, y: 2}
		expect(game.board[4][5].possible_moves().length).toBe 0
	
	it "ends the game on checkmate", ->
		board = "Q7/1R6/6k1/1R6 b"
		game = new Chess($(""), board)
		game.start()
		expect(game.active).toBe true
		game.board[0][0].make_move({x: 0, y: 2})
		expect(game.active).toBe false
