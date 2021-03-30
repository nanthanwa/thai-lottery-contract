const Migrations = artifacts.require('Migrations');

module.exports = function (deployer, network, addresses) {
  const [admin] = addresses;
  console.log('admin', admin);
  console.log('network', network);
  deployer.deploy(Migrations);
};
