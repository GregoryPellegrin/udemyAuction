//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction
{
    address payable public owner;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;

    address payable public highestBidder;
    mapping(address => uint) public bids;

    //the owner can finalize the auction and get the highestBindingBid only once
    bool public ownerFinalized = false;

    constructor ()
    {
        owner = payable(msg.sender);
        auctionState = State.Running;
    }

    // only the owner can cancel the Auction before the Auction has ended
    function cancelAuction () public onlyOwner
    {
        auctionState = State.Canceled;
    }

    // the main function called to place a bid
    function placeBid () public payable notOwner returns (bool)
    {
        // to place a bid auction should be running
        require(auctionState == State.Running, "Auction should running");
        // minimum value allowed to be sent
        // require(msg.value > 0.0001 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        // the currentBid should be greater than the highestBindingBid
        // Otherwise there's nothing to do.
        require(currentBid > highestBindingBid, "Bid too low");

        // updating the mapping variable
        bids[msg.sender] = currentBid;

        if (currentBid > bids[highestBidder])
        {
            // highestBidder is another bidder
            highestBidder = payable(msg.sender);
        }

        return true;
    }

    function finalizeAuction () public {
        // the auction has been Canceled or Ended
        require(auctionState == State.Canceled, "Need auction ended");

        // only the owner or a bidder can finalize the auction
        require(msg.sender == owner || bids[msg.sender] > 0, "Need to be owner or bidder");

        // the recipient will get the value
        address payable recipient;
        uint value;

        if (auctionState == State.Canceled)
        {
            // auction canceled, not ended
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else
        {
            // auction ended, not canceled
            if(msg.sender == owner && ownerFinalized == false)
            {
                //the owner finalizes the auction
                recipient = owner;
                value = highestBindingBid;

                //the owner can finalize the auction and get the highestBindingBid only once
                ownerFinalized = true;
            }
            else
            {
                // another user (not the owner) finalizes the auction
                if (msg.sender == highestBidder)
                {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }
                else
                {
                    //this is neither the owner nor the highest bidder (it's a regular bidder)
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // resetting the bids of the recipient to avoid multiple transfers to the same recipient
        bids[recipient] = 0;

        //sends value to the recipient
        recipient.transfer(value);
    }

    // declaring function modifiers
    modifier notOwner ()
    {
        require(msg.sender != owner, "Not the Owner");
        _;
    }

    modifier onlyOwner ()
    {
        require(msg.sender == owner, "Only the owner");
        _;
    }
}