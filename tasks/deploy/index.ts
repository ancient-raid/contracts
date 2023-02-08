import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

import type {
  Blacklist,
  Blacklist__factory,
  Hero,
  HeroMint,
  HeroMint__factory,
  Hero__factory,
  Marketplace,
  Marketplace__factory,
  ProxyAdmin,
  ProxyAdmin__factory,
  StakingPhase1,
  StakingPhase1__factory,
  TransparentUpgradeableProxy,
  TransparentUpgradeableProxy__factory,
  Warrior,
  Warrior__factory,
  WarriorMint,
  WarriorMint__factory,
  BlackCard,
  BlackCard__factory,
  Vault,
  Vault__factory,
  Random,
  Random__factory
} from "../../src/types";
import deployment from "../deployment.json";

// task("functionhash").setAction(async function (taskArguments: TaskArguments, { ethers }) {
//   const signers: SignerWithAddress[] = await ethers.getSigners();
//   console.log(signers[0]);
//   const id = ethers.utils.id("initialize()");
//   console.log(id);
// });

task("deploy:ProxyAdmin").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).deploy();
  await proxyAdmin.deployed();
  console.log("ProxyAdmin deployed to: ", proxyAdmin.address);
});

task("deploy:Blacklist").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const blacklistFactory = <Blacklist__factory>await ethers.getContractFactory("Blacklist");
  const blacklist = await blacklistFactory.connect(signers[0]).deploy();
  await blacklist.deployed();
  console.log("Blacklist deployed to: ", blacklist.address);
});

task("deploy:Hero").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();

  const heroFactory: Hero__factory = <Hero__factory>await ethers.getContractFactory("Hero");
  const hero: Hero = <Hero>await heroFactory.connect(signers[0]).deploy();
  await hero.deployed();
  console.log("Hero deployed to: ", hero.address);
});

task("deploy:Proxy").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const logic = config.Hero;
  const admin = config.ProxyAdmin;
  const data = ethers.utils.id("initialize()").slice(0, 10);
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyFactory = <TransparentUpgradeableProxy__factory>(
    await ethers.getContractFactory("TransparentUpgradeableProxy")
  );
  const proxy = await proxyFactory.connect(signers[0]).deploy(logic, admin, data);
  await proxy.deployed();
  console.log("Proxy deployed to: ", proxy.address);
});


task("deploy:HeroMint").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];
  const hero = config.HeroProxy;
  const busd = config.BUSD;
  const raid = config.RAID;
  const gold = config.Gold;

  const mintFactory: HeroMint__factory = <HeroMint__factory>await ethers.getContractFactory("HeroMint");
  const heroMint = <HeroMint>await mintFactory.connect(signers[0]).deploy(hero, busd, raid, gold);
  await heroMint.deployed();
  console.log("HeroMint deployed to: ", heroMint.address);
});

task("deploy:GetHeroMint").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];

  const mintFactory: HeroMint__factory = <HeroMint__factory>await ethers.getContractFactory("HeroMint");
  const heroMint = <HeroMint>await mintFactory.connect(signers[0]).attach(config.HeroMintV3);

  const tx = await heroMint.transferOwnership('0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359')
  const receipt = await tx.wait()
  console.log("transferOwnership = ", receipt.status)
  // const recipient = await heroMint.recipient();
  // const invitation = await heroMint.invitation();
  // console.log("HeroMint recipient : ", recipient);
  // console.log("HeroMint invitation : ", invitation);
});

task("deploy:HeroSetup").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];
  const heroFactory = <Hero__factory>await ethers.getContractFactory("Hero");
  const hero = await heroFactory.connect(signers[0]).attach(config.HeroProxy);


  console.log(await hero._random())

  // console.log(await hero.getTraits(1175))

  // const tx = await hero.setMinter("0x95B213Cf3A859dfC03a6CabD05e4992c29AFA0a7", true);
  // const receipt = await tx.wait();
  // console.log("setMinter = ", receipt.status);

  // const tx = await hero.setOperator('0x6c1bb29b967e174fa8e872bf4b4470770c0818b7', true)
  // const receipt = await tx.wait();
  // console.log("setOperator = ", receipt.status);

  // await hero.setBlacklist(config.Blacklist)
  // console.log("setBlacklist completed")
  // await hero.setBaseURI("https://metadata.ancientraid.com/hero/metadata/")
  // console.log("setMetadata completed")
});

task("deploy:setBlacklist").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];
  const blacklistFactory = <Blacklist__factory>await ethers.getContractFactory("Blacklist");
  const blacklist = await blacklistFactory.connect(signers[0]).attach(config.Blacklist);

  const tx = await blacklist.add([config.ElementNFT]);
  const receipt = await tx.wait();
  console.log("Blacklist added = ", receipt.status);
});

task("deploy:StakingPhase1").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const stakingFactory: StakingPhase1__factory = <StakingPhase1__factory>(
    await ethers.getContractFactory("StakingPhase1")
  );
  const staking = <StakingPhase1>await stakingFactory.connect(signers[0]).deploy();
  await staking.deployed();
  console.log("StakingPhase1 deployed to: ", staking.address);
});
task("deploy:V2StakingPhase1").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const stakingFactory: StakingPhase1__factory = <StakingPhase1__factory>(
    await ethers.getContractFactory("StakingPhase1")
  );
  const staking = <StakingPhase1>await stakingFactory.connect(signers[0]).deploy();
  await staking.deployed();
  console.log("StakingPhase1 V2 deployed to: ", staking.address);
});

task("deploy:ProxyStakingPhase1").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const logic = config.StakingPhase1;
  const admin = config.ProxyAdmin;
  const data = ethers.utils.id("initialize()").slice(0, 10);
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyFactory = <TransparentUpgradeableProxy__factory>(
    await ethers.getContractFactory("TransparentUpgradeableProxy")
  );
  const proxy = await proxyFactory.connect(signers[0]).deploy(logic, admin, data);
  await proxy.deployed();
  console.log("ProxyStakingPhase1 deployed to: ", proxy.address);
});

task("deploy:UpgradeStakingPhase1").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];

  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).attach(config.ProxyAdmin);
  // const data = ethers.utils.id("reinitialize()").slice(0, 10)

  // const iface = new ethers.utils.Interface(["function transferOwnership(address newOwner)"]);
  // const data = iface.encodeFunctionData("transferOwnership", [signers[0].address]);

  const tx = await proxyAdmin.upgrade(config.ProxyStakingPhase1, config.StakingPhase1V3);
  console.log("tx = ", tx.hash);
  const receipt = await tx.wait();
  console.log("upgrade StakingPhase1 = : ", receipt.status);
});

task("deploy:SetStaking").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const stakingFactory = <StakingPhase1__factory>await ethers.getContractFactory("StakingPhase1");
  const staking = await stakingFactory.connect(signers[0]).attach(config.ProxyStakingPhase1);

  const startBlock = 21810772;
  const endBlock = 23550423 //28800 * 30 * 2 + startBlock;
  const tx = await staking.setRewardBlocks(startBlock, endBlock);
  const receipt = await tx.wait();
  console.log("setRewardBlocks finished = ", receipt.status);
  const onChainStartBlock = await staking.startBlock();
  const onChainEndBlock = await staking.endBlock();
  console.log("onChainStartBlock = ", onChainStartBlock);
  console.log("onChainEndBlock = ", onChainEndBlock);
});

task("deploy:Marketplace").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const marketplaceFactory: Marketplace__factory = <Marketplace__factory>await ethers.getContractFactory("Marketplace");
  const marketplace = <Marketplace>await marketplaceFactory.connect(signers[0]).deploy();
  await marketplace.deployed();
  console.log("Marketplace deployed to: ", marketplace.address);
});

task("deploy:ProxyMarketplace").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const logic = config.Marketplace;
  const admin = config.ProxyAdmin;
  const data = ethers.utils.id("initialize()").slice(0, 10);
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyFactory = <TransparentUpgradeableProxy__factory>(
    await ethers.getContractFactory("TransparentUpgradeableProxy")
  );
  const proxy = await proxyFactory.connect(signers[0]).deploy(logic, admin, data);
  await proxy.deployed();
  console.log("ProxyMarketplace deployed to: ", proxy.address);
});


task("deploy:SetMarketplace").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const marketplaceFactory = <Marketplace__factory>await ethers.getContractFactory("Marketplace");
  const marketplace = await marketplaceFactory.connect(signers[0]).attach(config.ProxyMarketplace);

  let tx = await marketplace.setCooldown(24 * 60 * 60)
  let receipt = await tx.wait()
  console.log("setCooldown = ", receipt.status)
});

task("deploy:setConfig").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  let heroMintFactory = <HeroMint__factory>await ethers.getContractFactory("HeroMint");
  const config = (deployment as any)[network.name];
  // console.log("config=", config.HeroMint);
  const heroMint = await heroMintFactory.connect(signers[0]).attach(config.HeroMintV3);
  // await heroMint.setBusdPrice(ethers.utils.parseEther('75'))
  // await heroMint.setRaidPrice(ethers.utils.parseEther('100'))
  // await heroMint.setGoldPrice(ethers.utils.parseEther('200'))
  // await heroMint.setRecipient(signers[1].address)
  // await heroMint.setInvitation("0x6bAEf88ea37eEDE9f6407A4dE2BF81f3D4035A3A");
  // console.log("finished");

  const invitation = await heroMint.owner()
  console.log("invitation = ", invitation)
});

task("init").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  // const signers: SignerWithAddress[] = await ethers.getSigners();
  // await signers[0].sendTransaction({
  //   to: metamaskAddress,
  //   value: ethers.utils.parseEther('1000')
  // })
  // const iface = new ethers.utils.Interface(["function checkStakedOwner(uint256 tokenId)"]);
  // const data = iface.encodeFunctionData("checkStakedOwner", [ 50 ]);
  // console.log('data = ', data)
});


task("deploy:Warrior").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const factory: Warrior__factory = <Warrior__factory>await ethers.getContractFactory("Warrior");
  const warrior = <Warrior>await factory.connect(signers[0]).deploy();
  await warrior.deployed();
  console.log("Warrior deployed to: ", warrior.address);
});

task("deploy:BlackCard").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const factory: BlackCard__factory = <BlackCard__factory>await ethers.getContractFactory("BlackCard");
  const contract = <BlackCard>await factory.connect(signers[0]).deploy();
  await contract.deployed();
  console.log("BlackCard deployed to: ", contract.address);
});

task("deploy:WarriorProxy").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const logic = config.Warrior;
  const admin = config.ProxyAdmin;
  const data = ethers.utils.id("initialize()").slice(0, 10);
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyFactory = <TransparentUpgradeableProxy__factory>(
    await ethers.getContractFactory("TransparentUpgradeableProxy")
  );
  const proxy = await proxyFactory.connect(signers[0]).deploy(logic, admin, data);
  await proxy.deployed();
  console.log("WarriorProxy deployed to: ", proxy.address);
});

// address raid_,
// address busd_,
// address warrior_,
// address blackCard_,
// address gold_,
// address silver_,
// address copper_

task("deploy:WarriorMint").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const factory: WarriorMint__factory = <WarriorMint__factory>await ethers.getContractFactory("WarriorMint");
  const config = (deployment as any)[network.name];

  const raid = config.RAID
  const busd = config.BUSD
  const warrior = config.WarriorProxy
  const blackCard = config.BlackCard
  const gold = config.Gold
  const silver = config.Silver
  const copper = config.Copper

  const warriorMint = <WarriorMint>await factory.connect(signers[0]).deploy(
    raid,
    busd,
    warrior,
    blackCard,
    gold,
    silver,
    copper
  );
  await warriorMint.deployed();
  console.log("WarriorMint deployed to: ", warriorMint.address);
});


task("deploy:WarriorSetup").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];

  const warriorFactory = <Warrior__factory>await ethers.getContractFactory("Warrior");
  const warrior = await warriorFactory.connect(signers[0]).attach(config.WarriorProxy);

  // console.log("2406 = ", await warrior.getTraits(2406))
  // console.log("4236 = ", await warrior.getTraits(4236))
  // console.log("4237 = ", await warrior.getTraits(4237))
  // console.log("4238 = ", await warrior.getTraits(4238))
  // console.log("4239 = ", await warrior.getTraits(4239))

  // console.log(warrior.interface.encodeFunctionData("getTraits",[4238]))

  // warrior.callStatic

  // console.log(await warrior.getTraits(79))

  // const isAdmin = await warrior.isAdmin("0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359")
  // console.log("isAdmin = ", isAdmin)


  // const tx = await warrior.setOperator('0x6c1bb29b967e174fa8e872bf4b4470770c0818b7', true);
  // const receipt = await tx.wait();
  // console.log("warrior setOperator = ", receipt.status)


  // const blacklistedIds = [3764, 3851, 3852]

  // console.log("3764 isBlocked = ", await warrior.isBlocked(3764))
  // console.log("3851 isBlocked = ", await warrior.isBlocked(3851))
  // console.log("3852 isBlocked = ", await warrior.isBlocked(3852))
  // {
  //   const tx = await warrior.setBlocked(3764, true);
  //   const receipt = await tx.wait();
  //   console.log("warrior setBlocked = ", receipt.status)
  // }
  
  // {
  //   const tx = await warrior.setBlocked(3851, true);
  //   const receipt = await tx.wait();
  //   console.log("warrior setBlocked = ", receipt.status)
  // }
  
  // {
  //   const tx = await warrior.setBlocked(3852, true);
  //   const receipt = await tx.wait();
  //   console.log("warrior setBlocked = ", receipt.status)
  // }
  

  // const isMinter = await warrior.isMinter(config.WarriorMint)
  // console.log("isMinter = ", isMinter)
  const tx = await warrior.setMinter("0x95B213Cf3A859dfC03a6CabD05e4992c29AFA0a7", true);
  const receipt = await tx.wait();
  console.log("warrior setMinter = ", receipt.status)

  // {
  //   const tx = await warrior.setBaseURI("https://metadata.ancientraid.com/warrior/metadata/")
  //   const receipt = await tx.wait();
  //   console.log("setMetadata completed = ", receipt.status)
  // }
  
  // {
  //   await warrior.setBlacklist(config.Blacklist)
  //   const receipt = await tx.wait();
  //   console.log("setBlacklist completed = ", receipt.status)
  // }
  

  // {
  //   const warriorMintFactory = <WarriorMint__factory>await ethers.getContractFactory("WarriorMint");
  //   const warriorMint = await warriorMintFactory.connect(signers[0]).attach(config.WarriorMint);
  //   const warrior = await warriorMint.warrior()
  //   console.log(warrior)
  //   const isOperator = await warriorMint.isOperator('0xbcDF8496b79D6b3C001dDC63E2880d7afF1AB359');
  //   console.log("isOperator = ", isOperator)
  //   // const receipt = await tx.wait();
  //   // console.log("setBusdPrice = ", receipt.status)
  // }
  

  // console.log("warrior setMinter = ", receipt.status);
  // await hero.setBlacklist(config.Blacklist)
  // console.log("setBlacklist completed")
  // await warrior.setBaseURI("https://metadata.ancientraid.com/warrior/metadata/")
  // console.log("setMetadata completed")

  // {
  //   const blackCardFactory = <BlackCard__factory>await ethers.getContractFactory("BlackCard");
  //   const blackCard = await blackCardFactory.connect(signers[0]).attach(config.BlackCard);
  //   const isMinter = await blackCard.isMinter(config.WarriorMint)
  //   console.log("isMinter = ", isMinter)
  //   const tx = await blackCard.setMinter(config.WarriorMint, true)
  //   const receipt = await tx.wait();
  //   console.log("blackCard setMinter = ", receipt.status);
  // }
});


task("deploy:UpgradeHero").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();

  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).attach(config.ProxyAdmin);
  const data = ethers.utils.id("reinitialize3()").slice(0, 10);
  const tx = await proxyAdmin.upgradeAndCall(config.HeroProxy, config.HeroV4, data);
  // const tx = await proxyAdmin.upgrade(config.HeroProxy, config.HeroV3);
  const receipt = await tx.wait();
  console.log("upgrade Hero =  ", receipt.status);
});



task("deploy:UpgradeWarrior").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  
  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).attach(config.ProxyAdmin);
  const data = ethers.utils.id("reinitialize3()").slice(0, 10);
  const tx = await proxyAdmin.upgradeAndCall(config.WarriorProxy, config.WarriorV3, data);
  const receipt = await tx.wait();
  console.log("upgrade Warrior =  ", receipt.status);
});

task("deploy:UpgradeMarketplace").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];

  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).attach(config.ProxyAdmin);
  const data = ethers.utils.id("reinitialize4()").slice(0, 10);
  const tx = await proxyAdmin.upgradeAndCall(config.ProxyMarketplace, config.MarketplaceV4, data);
  const receipt = await tx.wait();
  console.log("upgrade Marketplace =  ", receipt.status);
});

task("deploy:Vault").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const vaultFactory: Vault__factory = <Vault__factory>await ethers.getContractFactory("Vault");
  const vault = <Vault>await vaultFactory.connect(signers[0]).deploy();
  await vault.deployed();
  console.log("Vault deployed to: ", vault.address);
});

task("deploy:VaultProxy").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const logic = config.Vault;
  const admin = config.ProxyAdmin;
  const data = ethers.utils.id("initialize()").slice(0, 10);
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const proxyFactory = <TransparentUpgradeableProxy__factory>(
    await ethers.getContractFactory("TransparentUpgradeableProxy")
  );
  const proxy = await proxyFactory.connect(signers[0]).deploy(logic, admin, data);
  await proxy.deployed();
  console.log("VaultProxy deployed to: ", proxy.address);
});

task("deploy:setVault").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const vaultFactory: Vault__factory = <Vault__factory>await ethers.getContractFactory("Vault");
  const vault = <Vault>await vaultFactory.connect(signers[0]).attach(config.VaultProxy);
  const tx = await vault.setAdmin(signers[0].address)
  const receipt = await tx.wait()
  console.log("Vault setAdmin  = ", receipt.status);
});

task("deploy:vaultWithdraw").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const vaultFactory: Vault__factory = <Vault__factory>await ethers.getContractFactory("Vault");
  const vault = <Vault>await vaultFactory.connect(signers[0]).attach(config.VaultProxy);
  const tx = await vault.adminWithdraw(config.RAID, ethers.utils.parseEther('1'), signers[0].address)
  const receipt = await tx.wait()
  console.log("Vault admin Withdraw  = ", receipt.status);
});


task("deploy:Random").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const randomFactory = await ethers.getContractFactory("Random");
  const random = await randomFactory.connect(signers[0]).deploy();
  await random.deployed();
  console.log("Random deployed to: ", random.address);
});

task("deploy:decode").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  // const signers: SignerWithAddress[] = await ethers.getSigners();
  // const randomFactory = await ethers.getContractFactory("Random");
  // const random = await randomFactory.connect(signers[0]).deploy();
  // await random.deployed();
  // console.log("Random deployed to: ", random.address);

  const iface = new ethers.utils.Interface(["withdraw(uint256,address,uint256,uint256,uint8,bytes32,bytes32)"]);
  const data = iface.decodeFunctionData("withdraw", "0da25b4800000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000e9e7cea3dedca5984780bafc599bd69add087d5600000000000000000000000000000000000000000000000270801d946c94000000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000f33343132373339323037343038393400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004425553440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000412dd9b39b6dab5723f63b15e7ba2c47f43b0cdd3f3e24f73c2ad252c063260c7a26beecedb900aac0b38e8b40bfd1979984eaf5c98b2ca865a647d891dd5e56ea1b00000000000000000000000000000000000000000000000000000000000000");

  console.log("data=", data)
});