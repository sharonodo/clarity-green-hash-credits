
import { describe, expect, it, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;
const wallet3 = accounts.get("wallet_3")!;

const contractName = "clarity_green_hash-credit";

describe("Green Hash Credits Contract", () => {
  beforeEach(() => {
    // Reset simnet state for each test
  });

  describe("Contract Deployment", () => {
    it("should initialize with correct token metadata", () => {
      const name = simnet.callReadOnlyFn(contractName, "get-name", [], deployer);
      const symbol = simnet.callReadOnlyFn(contractName, "get-symbol", [], deployer);
      const decimals = simnet.callReadOnlyFn(contractName, "get-decimals", [], deployer);
      const totalSupply = simnet.callReadOnlyFn(contractName, "get-total-supply", [], deployer);

      expect(name.result).toBeOk(Cl.stringAscii("Green Hash Credits"));
      expect(symbol.result).toBeOk(Cl.stringAscii("GHC"));
      expect(decimals.result).toBeOk(Cl.uint(6));
      expect(totalSupply.result).toBeOk(Cl.uint(0));
    });

    it("should set deployer as initial verifier", () => {
      const isVerifier = simnet.callReadOnlyFn(contractName, "is-verifier", [Cl.principal(deployer)], deployer);
      expect(isVerifier.result).toBeBool(true);
    });
  });

  describe("Verifier Management", () => {
    it("should allow owner to add verifiers", () => {
      const addVerifier = simnet.callPublicFn(
        contractName,
        "add-verifier",
        [Cl.principal(wallet1)],
        deployer
      );
      
      expect(addVerifier.result).toBeOk(Cl.bool(true));
      
      const isVerifier = simnet.callReadOnlyFn(contractName, "is-verifier", [Cl.principal(wallet1)], deployer);
      expect(isVerifier.result).toBeBool(true);
    });

    it("should not allow non-owner to add verifiers", () => {
      const addVerifier = simnet.callPublicFn(
        contractName,
        "add-verifier",
        [Cl.principal(wallet2)],
        wallet1
      );
      
      expect(addVerifier.result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED
    });

    it("should allow owner to remove verifiers", () => {
      // First add a verifier
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
      
      // Then remove them
      const removeVerifier = simnet.callPublicFn(
        contractName,
        "remove-verifier",
        [Cl.principal(wallet1)],
        deployer
      );
      
      expect(removeVerifier.result).toBeOk(Cl.bool(true));
      
      const isVerifier = simnet.callReadOnlyFn(contractName, "is-verifier", [Cl.principal(wallet1)], deployer);
      expect(isVerifier.result).toBeBool(false);
    });
  });

  describe("Miner Verification", () => {
    beforeEach(() => {
      // Add wallet1 as a verifier for miner verification tests
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
    });

    it("should allow verifiers to verify miners", () => {
      const verifyMiner = simnet.callPublicFn(
        contractName,
        "verify-miner",
        [
          Cl.principal(wallet2),
          Cl.uint(1000000), // 1 TH/s
          Cl.stringAscii("solar")
        ],
        wallet1
      );
      
      expect(verifyMiner.result).toBeOk(Cl.bool(true));
      
      const minerInfo = simnet.callReadOnlyFn(
        contractName,
        "get-miner-info",
        [Cl.principal(wallet2)],
        deployer
      );
      
      expect(minerInfo.result).toBeSome(
        Cl.tuple({
          "hash-power": Cl.uint(1000000),
          "renewable-energy-source": Cl.stringAscii("solar"),
          "verification-date": Cl.uint(simnet.blockHeight),
          "verified": Cl.bool(true)
        })
      );
    });

    it("should not allow non-verifiers to verify miners", () => {
      const verifyMiner = simnet.callPublicFn(
        contractName,
        "verify-miner",
        [
          Cl.principal(wallet3),
          Cl.uint(1000000),
          Cl.stringAscii("wind")
        ],
        wallet2
      );
      
      expect(verifyMiner.result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED
    });

    it("should not allow verifying the same miner twice", () => {
      // First verification
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
      
      // Second verification should fail
      const verifyAgain = simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(2000000), Cl.stringAscii("wind")],
        wallet1
      );
      
      expect(verifyAgain.result).toBeErr(Cl.uint(104)); // ERR_ALREADY_VERIFIED
    });

    it("should allow updating miner hash power", () => {
      // First verify miner
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
      
      // Update hash power
      const updateHashPower = simnet.callPublicFn(
        contractName,
        "update-miner-hash-power",
        [Cl.principal(wallet2), Cl.uint(2000000)],
        wallet1
      );
      
      expect(updateHashPower.result).toBeOk(Cl.bool(true));
      
      const minerInfo = simnet.callReadOnlyFn(
        contractName,
        "get-miner-info",
        [Cl.principal(wallet2)],
        deployer
      );
      
      expect((minerInfo.result as any).value.data["hash-power"]).toBeUint(2000000);
    });
  });

  describe("Credit Issuance", () => {
    beforeEach(() => {
      // Setup: Add verifier and verify a miner
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
    });

    it("should allow verifiers to issue credits to verified miners", () => {
      const issueCredits = simnet.callPublicFn(
        contractName,
        "issue-credits",
        [Cl.principal(wallet2), Cl.uint(1000000)], // 1 GHC
        wallet1
      );
      
      expect(issueCredits.result).toBeOk(Cl.uint(1)); // Credit ID
      
      const balance = simnet.callReadOnlyFn(
        contractName,
        "get-balance",
        [Cl.principal(wallet2)],
        deployer
      );
      
      expect(balance.result).toBeOk(Cl.uint(1000000));
    });

    it("should not allow issuing credits to unverified miners", () => {
      const issueCredits = simnet.callPublicFn(
        contractName,
        "issue-credits",
        [Cl.principal(wallet3), Cl.uint(1000000)],
        wallet1
      );
      
      expect(issueCredits.result).toBeErr(Cl.uint(103)); // ERR_MINER_NOT_VERIFIED
    });

    it("should track credit information correctly", () => {
      simnet.callPublicFn(
        contractName,
        "issue-credits",
        [Cl.principal(wallet2), Cl.uint(1000000)],
        wallet1
      );
      
      const creditInfo = simnet.callReadOnlyFn(
        contractName,
        "get-credit-info",
        [Cl.uint(1)],
        deployer
      );
      
      expect(creditInfo.result).toBeSome(
        Cl.tuple({
          "miner": Cl.principal(wallet2),
          "hash-power": Cl.uint(1000000),
          "energy-source": Cl.stringAscii("solar"),
          "issued-date": Cl.uint(simnet.blockHeight),
          "redeemed": Cl.bool(false),
          "redeemed-by": Cl.none(),
          "redemption-date": Cl.none()
        })
      );
    });
  });

  describe("Credit Redemption", () => {
    beforeEach(() => {
      // Setup: Add verifier, verify miner, and issue credits
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
      simnet.callPublicFn(
        contractName,
        "issue-credits",
        [Cl.principal(wallet2), Cl.uint(1000000)],
        wallet1
      );
    });

    it("should allow token holders to redeem credits", () => {
      const redeemCredits = simnet.callPublicFn(
        contractName,
        "redeem-credits",
        [Cl.uint(1), Cl.uint(500000)], // Redeem 0.5 GHC
        wallet2
      );
      
      expect(redeemCredits.result).toBeOk(Cl.bool(true));
      
      const balance = simnet.callReadOnlyFn(
        contractName,
        "get-balance",
        [Cl.principal(wallet2)],
        deployer
      );
      
      expect(balance.result).toBeOk(Cl.uint(500000)); // 0.5 GHC remaining
    });

    it("should update credit info after redemption", () => {
      simnet.callPublicFn(
        contractName,
        "redeem-credits",
        [Cl.uint(1), Cl.uint(500000)],
        wallet2
      );
      
      const creditInfo = simnet.callReadOnlyFn(
        contractName,
        "get-credit-info",
        [Cl.uint(1)],
        deployer
      );
      
      const creditData = (creditInfo.result as any).value.data;
      expect(creditData["redeemed"]).toBeBool(true);
      expect(creditData["redeemed-by"]).toBeSome(Cl.principal(wallet2));
      expect(creditData["redemption-date"]).toBeSome(Cl.uint(simnet.blockHeight));
    });

    it("should not allow redeeming insufficient balance", () => {
      const redeemCredits = simnet.callPublicFn(
        contractName,
        "redeem-credits",
        [Cl.uint(1), Cl.uint(2000000)], // More than available
        wallet2
      );
      
      expect(redeemCredits.result).toBeErr(Cl.uint(101)); // ERR_INSUFFICIENT_BALANCE
    });
  });

  describe("Token Transfer", () => {
    beforeEach(() => {
      // Setup: Add verifier, verify miner, and issue credits
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
      simnet.callPublicFn(
        contractName,
        "issue-credits",
        [Cl.principal(wallet2), Cl.uint(1000000)],
        wallet1
      );
    });

    it("should allow token transfers between accounts", () => {
      const transfer = simnet.callPublicFn(
        contractName,
        "transfer",
        [
          Cl.uint(300000), // 0.3 GHC
          Cl.principal(wallet2),
          Cl.principal(wallet3),
          Cl.none()
        ],
        wallet2
      );
      
      expect(transfer.result).toBeOk(Cl.bool(true));
      
      const balanceWallet2 = simnet.callReadOnlyFn(
        contractName,
        "get-balance",
        [Cl.principal(wallet2)],
        deployer
      );
      
      const balanceWallet3 = simnet.callReadOnlyFn(
        contractName,
        "get-balance",
        [Cl.principal(wallet3)],
        deployer
      );
      
      expect(balanceWallet2.result).toBeOk(Cl.uint(700000)); // 0.7 GHC
      expect(balanceWallet3.result).toBeOk(Cl.uint(300000)); // 0.3 GHC
    });

    it("should not allow unauthorized transfers", () => {
      const transfer = simnet.callPublicFn(
        contractName,
        "transfer",
        [
          Cl.uint(300000),
          Cl.principal(wallet2),
          Cl.principal(wallet3),
          Cl.none()
        ],
        wallet1 // Wrong sender
      );
      
      expect(transfer.result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED
    });
  });

  describe("Contract Pause Functionality", () => {
    it("should allow owner to pause contract", () => {
      const pauseContract = simnet.callPublicFn(contractName, "pause-contract", [], deployer);
      expect(pauseContract.result).toBeOk(Cl.bool(true));
      
      const isPaused = simnet.callReadOnlyFn(contractName, "is-contract-paused", [], deployer);
      expect(isPaused.result).toBeBool(true);
    });

    it("should prevent operations when paused", () => {
      simnet.callPublicFn(contractName, "pause-contract", [], deployer);
      
      const addVerifier = simnet.callPublicFn(
        contractName,
        "add-verifier",
        [Cl.principal(wallet1)],
        deployer
      );
      
      expect(addVerifier.result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED when paused
    });

    it("should allow owner to unpause contract", () => {
      simnet.callPublicFn(contractName, "pause-contract", [], deployer);
      
      const unpauseContract = simnet.callPublicFn(contractName, "unpause-contract", [], deployer);
      expect(unpauseContract.result).toBeOk(Cl.bool(true));
      
      const isPaused = simnet.callReadOnlyFn(contractName, "is-contract-paused", [], deployer);
      expect(isPaused.result).toBeBool(false);
    });
  });

  describe("Read-Only Functions", () => {
    it("should correctly identify verified miners", () => {
      simnet.callPublicFn(contractName, "add-verifier", [Cl.principal(wallet1)], deployer);
      simnet.callPublicFn(
        contractName,
        "verify-miner",
        [Cl.principal(wallet2), Cl.uint(1000000), Cl.stringAscii("solar")],
        wallet1
      );
      
      const isVerified = simnet.callReadOnlyFn(
        contractName,
        "is-verified-miner",
        [Cl.principal(wallet2)],
        deployer
      );
      
      expect(isVerified.result).toBeBool(true);
      
      const notVerified = simnet.callReadOnlyFn(
        contractName,
        "is-verified-miner",
        [Cl.principal(wallet3)],
        deployer
      );
      
      expect(notVerified.result).toBeBool(false);
    });

    it("should calculate mining rewards correctly", () => {
      const reward = simnet.callReadOnlyFn(
        contractName,
        "calculate-mining-reward",
        [Cl.uint(1000000), Cl.uint(24)], // 1 TH/s for 24 hours
        deployer
      );
      
      expect(reward.result).toBeUint(24000000);
    });
  });
});
