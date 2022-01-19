'reach 0.1';
"use strict";

const NftProps = Object({
    nftId: UInt,
    artistId: UInt,
    createdAt: Bytes(50), // Number of bytes that createdAt can take
    managerAddress: Address,
});

const AuctionProps = Object({
    nftPrice: UInt,
    timeout: UInt,
});

const BidderProps = {
    buyNft: Fun([UInt, UInt, UInt], Bool),
};

const OwnerInterface = {
    showOwner: Fun([UInt, UInt, Address], Null),
    informTimeout: Fun([], Null),
    getAuctionProps: Fun([], AuctionProps)
};
const BuyerInterface = {
    ...BidderProps,
    showOwner: Fun([UInt, UInt, Address], Null),
    informTimeout: Fun([], Null),
    noBuy: Fun([Bool], Null),
}
const CreatorInterface = {
    ...OwnerInterface,
    getNftProps: Fun([], NftProps),
};

const emptyAuction = {
    nftPrice: 0, timeout: 0
};

export const main = Reach.App(
    {},
    [
        Participant('Creator', CreatorInterface),
        ParticipantClass('Owner', OwnerInterface),
        ParticipantClass('Buyer', BuyerInterface),
        View('NFT', {owner: Address })
    ],
    (Creator, Owner,Buyer,vNFT) => {

        Creator.only(() => {
            const { nftId, artistId, createdAt, managerAddress } = declassify(interact.getNftProps());
        });
        Creator.publish(nftId, artistId, createdAt, managerAddress);
        Owner.only(() => {
            const amOwner = true;
            const { nftPrice, timeout } =declassify(interact.getAuctionProps());
        });
        commit();
        Owner.publish(nftPrice, timeout).when(amOwner).timeout(false);
        
        var owner = Creator;
        { vNFT.owner.set(owner); };
        invariant(balance() == 0);
        while (true) {
            commit();
            Buyer.only(() => {
                const buy = declassify(interact.buyNft(nftPrice, nftId, artistId)); // return true or false
                const buyNft = buy && this !== owner;
                const bidder = this;
            })
            Buyer.publish(buy,bidder);
            commit();
            Buyer.publish(buyNft).pay(nftPrice).when(buyNft).timeout(relativeTime(timeout), () => {
                each([Creator, Owner,Buyer], () => {
                    interact.informTimeout();
                })
                Anybody.publish();
                [owner] = [owner];
                continue;
            });
            each([Creator,Owner,Buyer], () => {
                interact.showOwner(nftId, nftPrice, bidder);
            });
            transfer(balance()).to(owner);
            [owner] = [owner];
            continue;
        };
        commit();

    });
