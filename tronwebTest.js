const {TronWeb} = require('tronweb');

const tronWeb = new TronWeb({
                                fullHost: "https://api.shasta.trongrid.io",
                                privateKey: "f60f9ef66177ad5d61c87a857a938d9a604e813e206fa663f3d995afeb9bf830"
                            });

const contractAddress = "TMzB9rdKu2eQuZaDEgeeRQkCzHz59DQi4C";

async function checkTotalSupply() {
    const contract = await tronWeb.contract().at(contractAddress);
    const totalSupply = await contract.totalSupply().call();
    console.log("Toplam Arz:", totalSupply.toString());
}

checkTotalSupply();