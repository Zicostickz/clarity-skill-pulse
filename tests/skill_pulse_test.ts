import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Previous tests remain unchanged...

Clarinet.test({
  name: "Ensure milestone reward validation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Register user
    let setup = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'register-user', [
        types.bool(false),
        types.list([types.ascii("javascript")])
      ], user1.address)
    ]);
    
    setup.receipts[0].result.expectOk();
    
    // Create goal
    let createGoal = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'create-goal', [
        types.ascii("Learn Clarity"),
        types.ascii("Master Clarity smart contract development")
      ], user1.address)
    ]);
    
    let goalId = createGoal.receipts[0].result.expectOk();
    
    // Try to add milestone with excessive reward
    let addInvalidMilestone = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'add-milestone', [
        goalId,
        types.ascii("Complete basic Clarity tutorial"),
        types.uint(20000)
      ], user1.address)
    ]);
    
    addInvalidMilestone.receipts[0].result.expectErr(types.uint(107));
    
    // Add valid milestone
    let addValidMilestone = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'add-milestone', [
        goalId,
        types.ascii("Complete basic Clarity tutorial"),
        types.uint(100)
      ], user1.address)
    ]);
    
    addValidMilestone.receipts[0].result.expectOk();
  }
});
