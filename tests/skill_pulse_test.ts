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
    
    // Verify registration
    let userInfo = chain.callReadOnlyFn(
      'skill_pulse',
      'get-user-info',
      [types.principal(user1.address)],
      deployer.address
    );
    
    let userData = userInfo.result.expectSome().expectTuple();
    assertEquals(userData['is-mentor'], types.bool(false));
    assertEquals(userData['reputation'], types.uint(0));
  }
});

Clarinet.test({
  name: "Test goal creation and management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    const mentor = accounts.get('wallet_2')!;
    
    // Register user and mentor
    let setup = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'register-user', [
        types.bool(false),
        types.list([types.ascii("javascript")])
      ], user1.address),
      Tx.contractCall('skill_pulse', 'register-user', [
        types.bool(true),
        types.list([types.ascii("javascript")])
      ], mentor.address)
    ]);
    
    setup.receipts.map(receipt => receipt.result.expectOk());
    
    // Create goal
    let block = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'create-goal', [
        types.ascii("Learn Clarity"),
        types.ascii("Master Clarity smart contract development")
      ], user1.address)
    ]);
    
    let goalId = block.receipts[0].result.expectOk();
    
    // Assign mentor
    let assignMentor = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'assign-mentor', [
        goalId,
        types.principal(mentor.address)
      ], user1.address)
    ]);
    
    assignMentor.receipts[0].result.expectOk();
    
    // Update goal status
    let updateStatus = chain.mineBlock([
      Tx.contractCall('skill_pulse', 'update-goal-status', [
        goalId,
        types.ascii("completed")
      ], user1.address)
    ]);
    
    updateStatus.receipts[0].result.expectOk();
  }
});