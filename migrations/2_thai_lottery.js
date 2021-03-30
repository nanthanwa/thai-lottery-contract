const ThaiLottery = artifacts.require('ThaiLottery');
const LinkTokenInterface = artifacts.require('LinkTokenInterface');
const Web3 = require('web3');

module.exports = async function (deployer, network, addresses) {
  // Use deployer to state migration tasks.
  const [admin] = addresses;
  console.log('admin', admin);
  console.log('network', network);
  try {
    if (network === 'development' || network === 'kovan') {
      const VRFCoordinator = '0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9';
      const LINKToken = '0xa36085F69e2889c224210F603D836748e7dC0088';
      const keyHash = '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4';
      const fee = Web3.utils.toWei('0.1', 'ether'); // 0.1 LINK
      await deployer.deploy(ThaiLottery, VRFCoordinator, LINKToken, keyHash, fee, { from: admin });
      const thaiLottery = await ThaiLottery.deployed();
      console.log('thaiLottery', thaiLottery.address);
      const result = await LinkTokenInterface.at('0xa36085F69e2889c224210F603D836748e7dC0088');
      console.log('result', result);
      // (thaiLottery.address, Web3.utils.toWei('1', 'ether'));
    }
    if (network == 'rinkeby') {
      const VRFCoordinator = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
      const LINKToken = '0x01be23585060835e02b77ef475b0cc51aa1e0709';
      const keyHash = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';
      const fee = Web3.utils.toWei('0.1', 'ether'); // 0.1 LINK
      await deployer.deploy(ThaiLottery, VRFCoordinator, LINKToken, keyHash, fee, { from: admin });
    }
  } catch (err) {
    console.error(err);
  }
};
