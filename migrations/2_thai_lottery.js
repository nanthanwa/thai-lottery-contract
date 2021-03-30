const ThaiLottery = artifacts.require('ThaiLottery');
const Web3 = require('web3');

module.exports = async function (deployer, network, addresses) {
  // Use deployer to state migration tasks.
  const [alice] = addresses;
  console.log('alice', alice);
  console.log('network', network);
  const VRFCoordinator = '0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9';
  const LINKToken = '0xa36085F69e2889c224210F603D836748e7dC0088';
  const keyHash = '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4';
  const fee = Web3.utils.toWei('0.1', 'ether'); // 0.1 LINK

  try {
    await deployer.deploy(ThaiLottery, VRFCoordinator, LINKToken, keyHash, fee, { from: alice });
  } catch (err) {
    console.error(err);
  }
};
