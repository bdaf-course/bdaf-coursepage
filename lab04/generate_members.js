const { ethers } = require("ethers");
const fs = require("fs");

const n = parseInt(process.argv[2]);
if (!n || n <= 0) {
  console.error("Usage: node generate_members.js <N>");
  process.exit(1);
}

const addresses = [];
for (let i = 0; i < n; i++) {
  const wallet = ethers.Wallet.createRandom();
  addresses.push(wallet.address);
}

const output = { count: addresses.length, addresses };
fs.writeFileSync("members.json", JSON.stringify(output, null, 2));
console.log(`Generated ${n} addresses and saved to members.json`);
