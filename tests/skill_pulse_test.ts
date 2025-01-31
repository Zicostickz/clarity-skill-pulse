import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure user registration works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;

    let block = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'register-user', [
        types.bool(false),
        types.list([types.ascii("javascript"), types.ascii("blockchain")])
      ], user1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    let userInfo = chain.callReadOnlyFn(
      'skill_pulse',
      'get-user-info',
      [types.principal(user1.address)],
      deployer.address
    );
    
    let userData = userInfo.result.expectSome().expectTuple();
    assertEquals(userData['is-mentor'], types.bool(false));
    assertEquals(userData['reputation'], types.uint(0));
    assertEquals(userData['rewards-balance'], types.uint(0));
  }
});

Clarinet.test({
  name: "Test milestone creation and completion",
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
    
    // Add milestone
    let addMilestone = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'add-milestone', [
        goalId,
        types.ascii("Complete basic Clarity tutorial"),
        types.uint(100)
      ], user1.address)
    ]);
    
    let milestoneId = addMilestone.receipts[0].result.expectOk();
    
    // Complete milestone
    let completeMilestone = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'complete-milestone', [
        milestoneId
      ], user1.address)
    ]);
    
    completeMilestone.receipts[0].result.expectOk();
    
    // Verify rewards balance
    let userInfo = chain.callReadOnlyFn(
      'skill_pulse',
      'get-user-info',
      [types.principal(user1.address)],
      user1.address
    );
    
    let userData = userInfo.result.expectSome().expectTuple();
    assertEquals(userData['rewards-balance'], types.uint(100));
  }
});
