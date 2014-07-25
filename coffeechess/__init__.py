from flask import Flask, render_template
app = Flask(__name__)

PROMOTION_PIECES = [('bishop', '9821'), ('knight', '9822'), ('queen', '9819'), ('rook', '9820')]

PIECES = [('rook', '9820')] * 2 + \
	[('knight', '9822')] * 2 + \
	[('bishop', '9821')] * 2 + \
	[('king', '9818'), ('queen', '9819')] + \
	[('pawn', '9823')] * 8

@app.route("/")
def main():
	return render_template('main.html', pieces=PIECES, promotion_pieces=PROMOTION_PIECES)
