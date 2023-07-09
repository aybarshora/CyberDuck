const { ethers, run, network } = require("hardhat");

async function main() {
  const deployedContract = await ethers.deployContract("CyberDuckCoin",["CyberDuckCoin", "CDC"]);

  await deployedContract.waitForDeployment();

  console.log("CyberDuckCoin Contract Address:", await deployedContract.getAddress());

  console.log(`Verifying contract on Etherscan...`);

  await deployedContract.getAddress();

  await run(`verify:verify`, {
    address: await deployedContract.getAddress(),
    constructorArguments: ["CyberDuckCoin", "CDC"],
  });
}


// async function verify(contractAddress, arguments) {
//   try {
//     await run("verify:verify", {
//       address: contractAddress,
//       constructorArguments: arguments,
//     });
//   } catch (e) {
//     if (e.message.toLowerCase.includes("already verified")) {
//       console.log("The contract already verified");
//     } else {
//       console.log(e);
//     }
//   }
// }
// }

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });