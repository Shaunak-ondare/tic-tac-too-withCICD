import React from 'react';

const Square = ({ value, onClick, isWinningSquare, index }) => {
  return (
    <button 
      className={`square ${value ? 'filled' : ''} ${isWinningSquare ? 'winning-square' : ''}`} 
      onClick={onClick}
      style={{ animationDelay: `${index * 0.05}s` }}
    >
      <span className={value === 'X' ? 'symbol-x' : 'symbol-o'}>{value}</span>
    </button>
  );
};

const Board = ({ board, onClick, winningLine }) => {
  return (
    <div className="board">
      {board.map((square, i) => (
        <Square 
          key={i} 
          index={i}
          value={square} 
          onClick={() => onClick(i)} 
          isWinningSquare={winningLine?.includes(i)}
        />
      ))}
    </div>
  );
};

export default Board;
