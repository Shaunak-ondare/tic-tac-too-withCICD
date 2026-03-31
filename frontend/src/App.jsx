import React, { useState, useEffect } from 'react';
import { io } from 'socket.io-client';
import Board from './components/Board';
import './App.css';

// In production, we'll read VITE_BACKEND_URL from the environment. For local dev, fallback to localhost:3001.
const URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3001';

function App() {
  const [socket, setSocket] = useState(null);
  const [gameState, setGameState] = useState('landing'); // landing, waiting, playing, game_over
  const [symbol, setSymbol] = useState(null); // 'X' or 'O'
  const [board, setBoard] = useState(Array(9).fill(null));
  const [nextTurn, setNextTurn] = useState('X');
  const [winner, setWinner] = useState(null);
  const [winningLine, setWinningLine] = useState(null);
  const [isDraw, setIsDraw] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    const newSocket = io(URL, { autoConnect: false });
    setSocket(newSocket);

    // Event listeners
    newSocket.on('waiting', (data) => {
      setGameState('waiting');
      setMessage(data.message);
    });

    newSocket.on('game_start', (data) => {
      setSymbol(data.symbol);
      setBoard(Array(9).fill(null));
      setNextTurn(data.turn);
      setWinner(null);
      setWinningLine(null);
      setIsDraw(false);
      setGameState('playing');
      setMessage(`Game Started! You are ${data.symbol}`);
    });

    newSocket.on('update_board', (data) => {
      setBoard(data.board);
      setNextTurn(data.nextTurn);
      
      if (data.winner || data.isDraw) {
        setWinner(data.winner);
        setWinningLine(data.winningLine);
        setIsDraw(data.isDraw);
        setGameState('game_over');
        
        if (data.winner) {
           // We'll calculate text in render
        } else {
           setMessage("It's a draw!");
        }
      }
    });

    newSocket.on('opponent_left', () => {
      setGameState('game_over');
      setMessage('Opponent disconnected.');
      setWinner('System'); // Treat as a win or just end game
    });

    return () => newSocket.close();
  }, [setSocket]);

  const findGame = () => {
    socket.connect();
    socket.emit('find_game');
  };

  const handleSquareClick = (index) => {
    if (gameState !== 'playing' || board[index] || nextTurn !== symbol) return;
    socket.emit('make_move', { index });
  };

  const playAgain = () => {
    setGameState('landing');
    setBoard(Array(9).fill(null));
    setWinner(null);
    setWinningLine(null);
    setMessage('');
    socket.disconnect(); // Reset the connection state to allow starting fresh
  };

  return (
    <div className="app-container">
      <div className="glass-panel">
        <header>
          <div className="logo">
            <span className="x-glow">X</span>
            <span className="o-glow">O</span>
          </div>
          <h1>Tic Tac Toe</h1>
        </header>

        <main>
          {gameState === 'landing' && (
            <div className="center-content fade-in">
              <p className="subtitle">Real-Time Multiplayer</p>
              <button className="primary-btn" onClick={findGame}>
                Find Match <span className="arrow">→</span>
              </button>
            </div>
          )}

          {gameState === 'waiting' && (
            <div className="center-content">
              <div className="loader"></div>
              <p className="pulse-text">{message}</p>
            </div>
          )}

          {(gameState === 'playing' || gameState === 'game_over') && (
            <div className="game-area fade-in">
              <div className="status-bar">
                <div className="player-info">
                  Your Symbol: <span className={symbol === 'X' ? 'symbol-x' : 'symbol-o'}>{symbol}</span>
                </div>
                
                {gameState === 'playing' && (
                  <div className={`turn-indicator ${nextTurn === symbol ? 'my-turn' : 'opponent-turn'}`}>
                    {nextTurn === symbol ? "It's your turn!" : "Waiting for opponent..."}
                  </div>
                )}
                
                {gameState === 'game_over' && winner && winner !== 'System' && (
                   <div className="turn-indicator game-over-text">
                     {winner === symbol ? "🎉 You Won!" : "💀 You Lost!"}
                   </div>
                )}
                {gameState === 'game_over' && isDraw && (
                   <div className="turn-indicator game-over-text draw-txt">
                     🤝 Draw!
                   </div>
                )}
                {gameState === 'game_over' && winner === 'System' && (
                   <div className="turn-indicator game-over-text warning-text">
                     ⚠️ {message}
                   </div>
                )}
              </div>

              <Board 
                board={board} 
                onClick={handleSquareClick} 
                winningLine={winningLine}
              />

              {gameState === 'game_over' && (
                <button className="primary-btn play-again-btn" onClick={playAgain}>
                  Play Again
                </button>
              )}
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

export default App;
