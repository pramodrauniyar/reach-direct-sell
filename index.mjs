import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
import { ask, yesno, done } from '@reach-sh/stdlib/ask.mjs';
(async () => {
    const stdlib = await loadStdlib();
    const startingBalance = stdlib.parseCurrency(10); // Start Balance
    const fmt = (x) => stdlib.formatCurrency(x, 4);
    const getBalance = async () => fmt(await stdlib.balanceOf(acc));

    const isCreator = await ask(
        `Are you Creator?`,
        yesno
    );
    const who = isCreator ? 'Creator' : 'Alice';

    let acc = null;
    const createAcc = await ask(
        `Would you like to create an account? (only possible on devnet)`,
        yesno
    );
    if (createAcc) {
        acc = await stdlib.newTestAccount(startingBalance);
    } else {
        const secret = await ask(
            `What is your account secret?`,
            (x => x)
        );
        acc = await stdlib.newAccountFromSecret(secret);
    }

    let ctc = null;
    if (isCreator) {
        ctc = acc.contract(backend);
        ctc.getInfo().then((info) => {
            console.log(`The contract is deployed as = ${info}`); });
    }

    const before = await getBalance();
    console.log(`Your balance is ${before}`);

    console.log("|-----------------------------------------------------------------------------------------------|");
    console.log(` ${who} has ${before} Algo`);
    console.log("|-----------------------------------------------------------------------------------------------|");

    async function later() {
        const after = await getBalance();
        console.log(` ${who} went from ${before} Algo to ${after} Algo`);
        console.log("|-----------------------------------------------------------------------------------------------|");
    }

    const nftProps = {
        nftId: stdlib.randomUInt(), //Random NFT ID
        artistId: stdlib.randomUInt(), // Random Artist ID
        createdAt: "Dartroom",
        managerAddress: acc.networkAccount.addr,
    };
    let interact = {};
    const makeOwner = async (acc,ctcC, who) => {
        var ctc;
        if(isCreator){
            ctc = acc.contract(backend, ctcC.getInfo());
        } else{
            const info = await ask(
                `Please paste the contract information:`,
                JSON.parse
            );
            ctc = acc.contract(backend,  info);
        }
        interact.showOwner = (nftId, nftPrice, owner)=>{
            if ( stdlib.addressEq(owner, acc.networkAccount.addr) ) {
                console.log("|-----------------------------------------------------------------------------------------------|");
                console.log(` New owner is (${who}) ${owner}\n NFT Price: ${fmt(nftPrice)} Algo\n NFT ID: #${nftId}`);
                console.log("|-----------------------------------------------------------------------------------------------|");

            };
        }
        interact.getAuctionProps = async ()=>{
            const price = await ask(
                `Enter NFT price for selling if you want to sell:`,
                stdlib.parseCurrency
            );
            const timeout = 20;
            console.log("|-----------------------------------------------------------------------------------------------|");
            console.log(`${who} set the selling price of NFT as ${fmt(price)} Algo`);
            console.log("|-----------------------------------------------------------------------------------------------|");
            return {nftPrice:price,timeout:timeout};
        }
        interact.buyNft=async (nftPrice, nftId, artistId) => {
            console.log(` NFT ID: #${nftId}\n Artist ID: #${artistId}\n NFT Price: ${fmt(nftPrice)} Algo`);
            const buy = await ask(
                `Want to buy?`,
                yesno
            );
            return buy;
        }
        interact.informTimeout=async () => {
            console.log(`Buyer didn't pay for NFT.`);
        }
        interact.noBuy = async (buy)=>{
            console.log(`buy=>`,buy);
            await later();
        }
        return  ctc.p.Owner(interact);
    };
    if(isCreator) {
        interact.getNftProps = () => {
            console.log(` Creator makes id #${nftProps.nftId}`);
            console.log(` Artist id #${nftProps.artistId}`);
            console.log(` CreatedAt: ${nftProps.createdAt}`);
            console.log(` Manager Address: ${nftProps.managerAddress}`);
            return nftProps;
        }
        interact.showOwner = (nftId, nftPrice, owner) => {

        }
        interact.informTimeout = async (nftId, nftPrice, owner) => {
            console.log(`Timeout!.`);
            await later();
            process.exit(0);
        }
    }
    var pr = [];
    if(isCreator){
        pr.push(ctc.p.Creator(interact));
        pr.push(makeOwner(acc,ctc,' Creator'));

    }else{
        pr.push(makeOwner(acc,ctc,' Alice'));
    }
    await Promise.all(pr);
    console.log("Done!");

})();
