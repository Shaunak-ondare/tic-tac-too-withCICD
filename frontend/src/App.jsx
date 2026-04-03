import React, { useEffect, useMemo, useState } from 'react';
import { io } from 'socket.io-client';
import Board from './components/Board';
import './App.css';

// In production, Nginx will proxy WebSockets from our own domain. For local dev, fallback to localhost:3001.
const URL = import.meta.env.VITE_BACKEND_URL || (import.meta.env.PROD ? '/' : 'http://localhost:3001');

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

  const runtimeConfig = useMemo(() => window.APP_CONFIG || {}, []);

  useEffect(() => {
    const socketUrl = runtimeConfig.API_URL || (import.meta.env.PROD ? '/' : 'http://localhost:3001');
    const newSocket = io(socketUrl, { autoConnect: false });
    setSocket(newSocket);

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

        if (!data.winner) {
          setMessage("It's a draw!");
        }
      }
    });

    newSocket.on('opponent_left', () => {
      setGameState('game_over');
      setMessage('Opponent disconnected.');
      setWinner('System');
    });

    return () => newSocket.close();
  }, []);

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
    socket.disconnect();
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
                Find Match <span className="arrow">-&gt;</span>
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
                    {nextTurn === symbol ? "It's your turn!" : 'Waiting for opponent...'}
                  </div>
                )}

                {gameState === 'game_over' && winner && winner !== 'System' && (
                  <div className="turn-indicator game-over-text">
                    {winner === symbol ? 'You Won!' : 'You Lost!'}
                  </div>
                )}
                {gameState === 'game_over' && isDraw && (
                  <div className="turn-indicator game-over-text draw-txt">Draw!</div>
                )}
                {gameState === 'game_over' && winner === 'System' && (
                  <div className="turn-indicator game-over-text warning-text">{message}</div>
                )}
              </div>

              <Board board={board} onClick={handleSquareClick} winningLine={winningLine} />

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
