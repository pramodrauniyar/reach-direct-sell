import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);
const thread = async (f) => await f();
export class Signal {
    constructor() {
        const me = this;
        this.Buyer = new Promise((resolve) => { me.r = resolve; });
    }
    wait() { return this.Buyer; }
    notify() { this.r(true); }
};

(async () => {
    const startingBalance = stdlib.parseCurrency(100);
    const fmt = (x) => stdlib.formatCurrency(x, 4);
    const getBalance = async (acc) => fmt(await stdlib.balanceOf(acc));
    const [ accA, accB, accC ] =
        await stdlib.newTestAccounts(3, startingBalance);
    accA.setDebugLabel('A');
    accB.setDebugLabel('B');
    accC.setDebugLabel('C');

    const ctcA = accA.contract(backend);
    const before = await getBalance(accA);
    console.log(`Your balance is ${before}`);
    console.log("|-----------------------------------------------------------------------------------------------|");
    console.log(` A has ${before} Algo`);
    console.log("|-----------------------------------------------------------------------------------------------|");


    const ctcB = accB.contract(backend, ctcA.getInfo());
    const ctcC = accC.contract(backend, ctcA.getInfo());
    const ready = new Signal();

    const LOG = (...args) => {
        console.log("");
        console.log(...args);
        console.log("");

    };

    const aP = ctcA.p.Creator({
        ready: () => {
            LOG(`A says its ready`);
            ready.notify();
        },
        log: (...args) => LOG(`A sees`, ...args),
        checkBalance: async ()=>{
            const after = await getBalance(accA);
            console.log(`After your balance is ${after}`);

        }
    });

    await ready.wait();

    await ctcB.a.Buyer.put(stdlib.parseCurrency(10));
    await ctcC.a.Buyer.put(stdlib.parseCurrency(5));
    await ctcA.a.Buyer.done();


    await aP;



})();
