const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

let waitingPlayer = null;
const rooms = {};

// Helper to check for a winner
const calculateWinner = (board) => {
  const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6]             // diagonals
  ];
  for (let i = 0; i < lines.length; i++) {
    const [a, b, c] = lines[i];
    if (board[a] && board[a] === board[b] && board[a] === board[c]) {
      return { winner: board[a], line: [a, b, c] };
    }
  }
  return null;
};

io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('find_game', () => {
    if (waitingPlayer && waitingPlayer.id !== socket.id) {
      // Create a game room
      const roomName = `room_${waitingPlayer.id}_${socket.id}`;
      socket.join(roomName);
      waitingPlayer.join(roomName);

      rooms[roomName] = {
        players: {
          [waitingPlayer.id]: 'X',
          [socket.id]: 'O'
        },
        board: Array(9).fill(null),
        xIsNext: true,
      };

      // Notify players
      io.to(waitingPlayer.id).emit('game_start', { symbol: 'X', turn: 'X' });
      io.to(socket.id).emit('game_start', { symbol: 'O', turn: 'X' });
      
      console.log(`Game started in room ${roomName}`);
      waitingPlayer = null;
    } else {
      waitingPlayer = socket;
      socket.emit('waiting', { message: 'Waiting for an opponent...' });
    }
  });

  socket.on('make_move', ({ index }) => {
    // Find the room the player is in
    const roomName = Array.from(socket.rooms).find(r => r.startsWith('room_'));
    if (!roomName || !rooms[roomName]) return;

    const game = rooms[roomName];
    const symbol = game.players[socket.id];
    
    // Check if it's the correct turn and valid cell
    if ((game.xIsNext && symbol === 'X') || (!game.xIsNext && symbol === 'O')) {
      if (!game.board[index]) {
        game.board[index] = symbol;
        game.xIsNext = !game.xIsNext;
        
        const winInfo = calculateWinner(game.board);
        const isDraw = !game.board.includes(null);

        io.to(roomName).emit('update_board', {
          board: game.board,
          nextTurn: game.xIsNext ? 'X' : 'O',
          winner: winInfo ? winInfo.winner : null,
          winningLine: winInfo ? winInfo.line : null,
          isDraw: isDraw
        });
      }
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    if (waitingPlayer && waitingPlayer.id === socket.id) {
      waitingPlayer = null;
    }
    // Handle player leaving active game
    const roomName = Array.from(socket.rooms).find(r => r.startsWith('room_'));
    if (roomName) {
      io.to(roomName).emit('opponent_left');
      delete rooms[roomName];
    }
  });
});

const PORT = 3001;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
