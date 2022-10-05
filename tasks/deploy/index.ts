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
  MockToken,
  MockToken__factory,
  Multicall2,
  Multicall2__factory,
  ProxyAdmin,
  ProxyAdmin__factory,
  StakingPhase1,
  StakingPhase1__factory,
  TransparentUpgradeableProxy,
  TransparentUpgradeableProxy__factory,
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

  const recipient = await heroMint.recipient();
  const invitation = await heroMint.invitation();
  console.log("HeroMint recipient : ", recipient);
  console.log("HeroMint invitation : ", invitation);
});

task("deploy:HeroSetup").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];
  const heroFactory = <Hero__factory>await ethers.getContractFactory("Hero");
  const hero = await heroFactory.connect(signers[0]).attach(config.HeroProxy);

  const tx = await hero.setMinter(config.HeroMintV3, true);
  const receipt = await tx.wait();
  console.log("setMinter = ", receipt.status);

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

  const tx = await blacklist.add([config.ToFunFT]);
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
  const endBlock = 28800 * 30 + startBlock;
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

task("deploy:UpgradeMarketplace").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const config = (deployment as any)[network.name];

  const proxyAdminFactory = <ProxyAdmin__factory>await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await proxyAdminFactory.connect(signers[0]).attach(config.ProxyAdmin);
  const data = ethers.utils.id("reinitialize()").slice(0, 10);
  const tx = await proxyAdmin.upgradeAndCall(config.ProxyMarketplace, config.MarketplaceV2, data);
  const receipt = await tx.wait();
  console.log("upgrade Marketplace = : ", receipt.status);
});

task("deploy:SetMarketplace").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const config = (deployment as any)[network.name];
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const marketplaceFactory = <Marketplace__factory>await ethers.getContractFactory("Marketplace");
  const marketplace = await marketplaceFactory.connect(signers[0]).attach(config.ProxyMarketplace);

  // let tx = await marketplace.setFloorPrice(ethers.utils.parseEther('5358'))
  // let receipt = await tx.wait()
  // console.log("setFloorPrice = ", receipt.status)
});

task("deploy:setConfig").setAction(async function (taskArguments: TaskArguments, { ethers, network }) {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  let heroMintFactory = <HeroMint__factory>await ethers.getContractFactory("HeroMint");
  const config = (deployment as any)[network.name];
  console.log("config=", config.HeroMint);
  const heroMint = await heroMintFactory.connect(signers[0]).attach(config.HeroMint);
  // await heroMint.setBusdPrice(ethers.utils.parseEther('75'))
  // await heroMint.setRaidPrice(ethers.utils.parseEther('100'))
  // await heroMint.setGoldPrice(ethers.utils.parseEther('200'))
  // await heroMint.setRecipient(signers[1].address)
  // await heroMint.setInvitation("0xBAED839291A28CbB02C31aE268a8797D02a4c0de");
  // console.log("finished");
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
