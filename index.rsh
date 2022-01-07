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
        var owner = Creator;
        { vNFT.owner.set(owner); };
        invariant(balance() == 0);
        while (true) {
            commit();
            Owner.only(() => {
                const amOwner = this == owner;
                const { nftPrice, timeout } =
                    amOwner ? declassify(interact.getAuctionProps()) : emptyAuction;
            });
            Owner.publish(nftPrice, timeout).when(amOwner).timeout(false);
            commit();
            Buyer.only(() => {
                const buy = declassify(interact.buyNft(nftPrice, nftId, artistId));
                const buyNft = buy && this !== owner;
                const bidder = this;
                if(!buy){
                    interact.noBuy(buy);
                }
            })
            Buyer.publish(buy,bidder);
            if(!buy){
                commit();
                exit();
            }
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

            transfer((owner == Creator ? nftPrice * 15 / 100 : nftPrice * 5 / 100)).to(managerAddress);
            transfer((owner == Creator ? 0 : nftPrice / 10 )).to(Creator);
            transfer(balance()).to(owner);

            [owner] = [bidder];
            continue;
        };
        commit();
        // exit();
    });
