import { useState, useCallback, useEffect, useMemo } from "react";
import { useWallet } from "./useWallet";
import { formatResult } from "../utils/formatResult";

export const useBalance = () => {
  const { provider, account } = useWallet();
  const [balance, setBalance] = useState();

  const getBalance = useCallback(async () => {
    if (!provider || !account) {
      setBalance(undefined);
      return;
    }

    try {
      const result = await provider.getBalance(account);
      setBalance(formatResult(result, "eth"));
    } catch (error) {
      console.error("Failed to fetch balance:", error);
      setBalance(undefined);
    }
  }, [provider, account]);

  useEffect(() => {
    getBalance();
  }, [provider, account, getBalance]);

  return useMemo(
    () => ({
      balance,
      getBalance,
    }),
    [balance, getBalance]
  );
};
