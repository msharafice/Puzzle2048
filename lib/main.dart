import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: Puzzle2048(),
    );
  }
}

class Puzzle2048 extends StatefulWidget {
  const Puzzle2048({super.key});

  @override
  _Puzzle2048State createState() => _Puzzle2048State();
}

class _Puzzle2048State extends State<Puzzle2048> {
  List<List<int>> board = List.generate(4, (_) => List.filled(4, 0));
  int score = 0;
  int highScore = 856;
  List<List<List<int>>> history = [];
  List<int> scoreHistory = [];

  Offset _startSwipePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _addNewTile();
    _addNewTile();
  }

  void _saveGameState() {
    history.add(List.generate(4, (i) => List.from(board[i])));
    scoreHistory.add(score);
  }

  void _addNewTile() {
    List<int> emptyTiles = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (board[i][j] == 0) {
          emptyTiles.add(i * 4 + j);
        }
      }
    }

    if (emptyTiles.isNotEmpty) {
      int index = emptyTiles[(emptyTiles.length * 0.5).toInt()];
      int row = index ~/ 4;
      int col = index % 4;
      board[row][col] = [2, 4][(index % 2)];
    }
  }

  void _move(Direction direction) {
    bool changed = false;
    _saveGameState();

    setState(() {
      switch (direction) {
        case Direction.up:
          for (int col = 0; col < 4; col++) {
            List<int> column = [
              board[0][col],
              board[1][col],
              board[2][col],
              board[3][col]
            ];
            List<int> newColumn = _compressAndMerge(column);
            for (int row = 0; row < 4; row++) {
              if (board[row][col] != newColumn[row]) {
                changed = true;
              }
              board[row][col] = newColumn[row];
            }
          }
          break;
        case Direction.down:
          for (int col = 0; col < 4; col++) {
            List<int> column = [
              board[0][col],
              board[1][col],
              board[2][col],
              board[3][col]
            ];
            List<int> newColumn =
                _compressAndMerge(column.reversed.toList()).reversed.toList();
            for (int row = 0; row < 4; row++) {
              if (board[row][col] != newColumn[row]) {
                changed = true;
              }
              board[row][col] = newColumn[row];
            }
          }
          break;
        case Direction.left:
          for (int row = 0; row < 4; row++) {
            List<int> line = board[row];
            List<int> newLine = _compressAndMerge(line);
            if (line != newLine) {
              changed = true;
            }
            board[row] = newLine;
          }
          break;
        case Direction.right:
          for (int row = 0; row < 4; row++) {
            List<int> line = board[row];
            List<int> newLine =
                _compressAndMerge(line.reversed.toList()).reversed.toList();
            if (line != newLine) {
              changed = true;
            }
            board[row] = newLine;
          }
          break;
      }

      if (changed) {
        _addNewTile();
        score += 10;
      }
    });
  }

  List<int> _compressAndMerge(List<int> line) {
    List<int> newLine = List.filled(4, 0);
    int insertPos = 0;
    for (int i = 0; i < 4; i++) {
      if (line[i] != 0) {
        if (insertPos > 0 && newLine[insertPos - 1] == line[i]) {
          newLine[insertPos - 1] *= 2;
          score += newLine[insertPos - 1];
        } else {
          newLine[insertPos] = line[i];
          insertPos++;
        }
      }
    }
    return newLine;
  }

  void _undo() {
    if (history.isNotEmpty) {
      setState(() {
        board = history.last;
        score = scoreHistory.last;
        history.removeLast();
        scoreHistory.removeLast();
      });
    }
  }

  void _reset() {
    setState(() {
      board = List.generate(4, (_) => List.filled(4, 0));
      score = 0;
      _addNewTile();
      _addNewTile();
    });
    history.clear();
    scoreHistory.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 231, 224, 216),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: GestureDetector(
        onPanStart: (details) {
          _startSwipePosition = details.localPosition;
        },
        onPanEnd: (details) {
          Offset _endSwipePosition = details.velocity.pixelsPerSecond;
          double dx = _endSwipePosition.dx - _startSwipePosition.dx;
          double dy = _endSwipePosition.dy - _startSwipePosition.dy;

          if (dx.abs() > dy.abs()) {
            if (dx > 0) {
              _move(Direction.right);
            } else {
              _move(Direction.left);
            }
          } else {
            if (dy > 0) {
              _move(Direction.down);
            } else {
              _move(Direction.up);
            }
          }
        },
        child: Center(child: _buildBoard()),
      ),
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '2048',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: <Widget>[
                    _buildScoreContainer("SCORE", score),
                    SizedBox(width: 10),
                    _buildScoreContainer("HIGH SCORE", highScore),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildUndoContainer(),
                SizedBox(width: 10),
                _buildResetContainer(),
              ],
            ),
          ),
          // ثابت نگه داشتن کادر بازی
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF8C7B6C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: GridView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // جلوگیری از اسکرول
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14.0,
                mainAxisSpacing: 14.0,
              ),
              children: List.generate(16, (index) {
                int row = index ~/ 4;
                int col = index % 4;
                int value = board[row][col];

                Color boxColor;
                if (value == 0) {
                  boxColor = Color(0xFFC8C0B3); // برای کادر خالی
                  ;
                } else if (value == 2) {
                  boxColor = Color(0xFFF9F0D1);
                } else if (value == 4) {
                  boxColor = Color(0xFFF5E1A4);
                } else if (value == 8) {
                  boxColor = Color(0xFFFF8C2E);
                } else if (value == 16) {
                  boxColor = Color(0xFFFF7037);
                } else if (value == 32) {
                  boxColor = Color(0xFFF26B57);
                } else if (value == 64) {
                  boxColor = Color(0xFFEB4C2A);
                } else if (value == 128) {
                  boxColor = Color(0xFFF6D802);
                } else {
                  boxColor = Colors.grey[300]!;
                }

                return Container(
                  alignment: Alignment.center,
                  height: 65.0,
                  width: 65.0,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: value == 0
                      ? null
                      : Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: value > 4 ? Colors.white : Colors.black,
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreContainer(String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF8C7B6C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '$value',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUndoContainer() {
    return Container(
      width: 80,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF8C7B6C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(Icons.undo, color: Colors.white),
        onPressed: _undo,
      ),
    );
  }

  Widget _buildResetContainer() {
    return Container(
      width: 80,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF8C7B6C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(Icons.refresh, color: Colors.white),
        onPressed: _reset,
      ),
    );
  }
}

enum Direction { up, down, left, right }
