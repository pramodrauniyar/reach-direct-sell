'reach 0.1';
'use strict';

export const main = Reach.App(() => {
    const Creator = Participant('Creator', {
        ready: Fun([], Null),
        log: Fun(true, Null),
        checkBalance:Fun([], Null)
    });
    const Buyer = API('Buyer', {
        put: Fun([UInt], UInt),
        done: Fun([], Null),
    });
    init();

    Creator.publish();
    //const M = new Map(UInt);
    Creator.interact.ready();

    const [done, amt] = parallelReduce([false, 0])
        .invariant(balance() == 0)
        .while(true)
        .api(Buyer.done, () => {
            assume(this == Creator);
        }, () => 0, (k) => {
            require(this == Creator);
            k(null);
            Creator.interact.log('Done!');
            return [ true, amt ];
        })
        .api(Buyer.put, (x) => x, (x, k) => {
            k(x);
            Creator.interact.log(this, 'put', x);
            Creator.interact.checkBalance();
            transfer(x).to(Creator);
            return [ done,x ];
        })

    commit();
    exit();
});
