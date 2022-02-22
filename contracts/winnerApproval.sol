// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WinnerApproval is Ownable {
    /// Winner Vote should require three unique people to have to verify
    /// that you completed the program before you're accepted.
    /// All of these people have to be past winners.
    /// Once you're accepted, then you can mint the token

    uint private numApprovalsRequired;
    IERC20 private token;
    uint private minNumTokens;

    event WinnerVerified(address indexed _user, bool _byOwner, bool _byApproval);
    event ApprovalGranted(address indexed _approver, address _approvee);

    struct winnerDetails {
        bool winner;
        address[] winnerApprovals;
    }
    mapping(address => winnerDetails) private winners;

    constructor (uint _numApproversRequired, IERC20 _token, uint _minNumberTokens) {
        numApprovalsRequired = _numApproversRequired;
        token = _token;
        minNumTokens = _minNumberTokens;
    }

    /// Modifer for onlyWinners
    modifier onlyWinners {
        require(winners[msg.sender].winner, "You have not been verified a winner");
        _;
    }
    
    function hasTokens(address _user) view private returns (bool) {
        return token.balanceOf(_user) >= minNumTokens * 10**18;
    }

    function ownerAddWinner(address _winner) external onlyOwner {
        winners[_winner].winner = true;
        winners[_winner].winnerApprovals.push(msg.sender);
        emit WinnerVerified(_winner, true, false);
    }

    function checkWinnerStatus(address _user) public view returns (bool) {
        return winners[_user].winner;
    }

    function checkApprovers(address _user) public view returns (address [] memory) {
        return winners[_user].winnerApprovals;
    }

    function verifyWinner(address _user) public {
        /// Verifies if you have enough approvals and adds you as a winner
        /// Throws an error if you are already an approved winner
        /// Throws an error if you do not have enough approvals
        require(!winners[_user].winner, "Already verified as a winner");
        require(winners[_user].winnerApprovals.length >= numApprovalsRequired, "Not enough approvers");

        winners[_user].winner = true;
        emit WinnerVerified(_user, false, true);
    }

    function addApproval(address _user) public {
        /// Adds senders approval to the approved list
        /// Throws an error if the approver is not on the winner list
        /// Throws an error if the approver is already on the approver list
        /// Throws an error if the user is already a winner
        /// Throws an error if the users does not have enough tokens

        require(checkWinnerStatus(msg.sender), "Approver not on winner list");
        require(hasTokens(_user), "User does not have enough tokens");
        require(!winners[_user].winner, "User already on winner list");

        /// Checking if approver has already approved
        bool alreadyApproved = false;
        for(uint i = 0; i < winners[_user].winnerApprovals.length; i++) {
            if (winners[_user].winnerApprovals[i] == msg.sender) {
                alreadyApproved = true;
                break;
            }
        }
        require(!alreadyApproved, "Approval already granted for user from approver");

        winners[_user].winnerApprovals.push(msg.sender);

        emit ApprovalGranted(msg.sender, _user);
    }

}