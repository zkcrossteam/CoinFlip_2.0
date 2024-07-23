import { useState, useEffect, useCallback } from "react";

import { useFunction } from ".";

export const useGame = () => {
  const [betAmount, setBetAmount] = useState(0.001);
  const [betChoice, setBetChoice] = useState(null);
  const [shouldFlip, setShouldFlip] = useState(false);

  const arg1 = BigInt(Math.floor(Math.random() * 10000) + 1);
  const arg2 = BigInt("16831113364524873086851045530299305127001212719560801042961261036226161369175");
  const doFlip = useFunction("bet", betAmount, [arg1, arg2, betChoice]);
  const collectFunds = useFunction("withdrawPlayerBalance");

  const handleBet = useCallback((choice) => {
    setBetChoice(choice);
    setShouldFlip(true);
  }, []);

  useEffect(() => {
    if (shouldFlip) {
      doFlip();
      setShouldFlip(false);
    }
  }, [shouldFlip, doFlip]);

  return {
    betAmount,
    setBetAmount,
    handleBet,
    collectFunds,
  };
};
