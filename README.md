# reach-direct-sell
This is simple program where Creator creats a NFT and initially becomes owner. Once becomes owner, then it sets the NFT properties(price and timeout).

## first compile the reach program

```
REACH_CONNECTOR_MODE=ALGO  REACH_DEBUG=0 ./reach compile
```
## run the program as Creator

```
REACH_CONNECTOR_MODE=ALGO  REACH_DEBUG=0 ./reach run
```

## Then in the new terminal run the program as owner

```
REACH_CONNECTOR_MODE=ALGO  REACH_DEBUG=0 ./reach run
```


