// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownable.sol";

contract Mydao is Ownable {
    //Address of admin

    address public admin;
    uint256 memberCount;
    address charity = 0xE4a93C164F1C194dFB58C513D302e7d912e8915f;
    bool destroyed;
    bool public newAdmin;

    enum proposalNames {
        adminChange,
        donate,
        destroy
    }

    constructor() {
        
        admin = msg.sender;
        proposals.push(
            Proposal(
                proposalNames.adminChange,
                ProposalStatus.pending,
                0,
                msg.sender
            )
        );
        proposals.push(
            Proposal(
                proposalNames.donate,
                ProposalStatus.pending,
                0,
                msg.sender
            )
        );
        proposals.push(
            Proposal(
                proposalNames.destroy,
                ProposalStatus.pending,
                0,
                msg.sender
            )
        );
    }

    

    //Member details

    enum VoteStatus {
        voted,
        not_voted,
        active,
        inactive
    }

    struct Member {
        address memberAddress;
        uint256 contributions;
        VoteStatus voteStatus;
    }

    Member member;

    mapping(uint256 => Member) memberDetails;

    //Registration fees 1 eth

    function register() public payable {
        require(!destroyed, "Contract destroyed");
        for (uint256 i = 0; i < memberCount; i++) {
            if (memberDetails[i].memberAddress == msg.sender) {
                revert("Member already exist !");
            }
        }
        require(msg.value >= 1e9);
        memberDetails[memberCount].memberAddress = msg.sender;
        memberDetails[memberCount].contributions = msg.value;
        memberDetails[memberCount].voteStatus = VoteStatus.inactive;
        memberCount++;
    }

    //View contributions

    function myContribution() public view returns (uint256) {
        require(!destroyed, "Contract destroyed");
        return memberDetails[findMemberId()].contributions;
    }

    //View members

    function viewMembers(uint256 _id) public view returns (address, uint256) {
        require(!destroyed, "Contract destroyed");

        require(_id < memberCount, "Member doesn't exist");
        return (
            memberDetails[_id].memberAddress,
            memberDetails[_id].contributions
        );
    }

    //Find memberId

    function findMemberId() internal view returns (uint256) {
        require(!destroyed, "Contract destroyed");

        uint256 id;
        bool found;

        for (uint256 i = 0; i < memberCount; i++) {
            if (memberDetails[i].memberAddress == msg.sender) {
                id = i;
                found = true;
            }
        }
        require(found, "Member doesn't exist !");
        return id;
    }

    //Proposals

    enum ProposalStatus {
        accepted,
        rejected,
        pending
    }

    struct Proposal {
        proposalNames proposalName;
        ProposalStatus proposalStatus;
        uint256 votesReceived;
        address ProposalsubmitedBy;
    }

    struct ProposalSubmission {
        Proposal proposalStruct;
        uint256 blockNumber;
    }

    Proposal[] public proposals;

    ProposalSubmission[] internal submittedProposals;

    //Submitting proposal

    function newSubmission(uint256 _proposalId) public payable {
        require(!destroyed, "Contract destroyed");

        require(memberDetails[findMemberId()].memberAddress == msg.sender);
        require(msg.value >= 1e9, "Not enough eth to submit this proposal");
        require(_proposalId < proposals.length, "No proposal found");
        if (submittedProposals.length != 0) {
            require(
                submittedProposals[submittedProposals.length - 1]
                    .proposalStruct
                    .proposalStatus != ProposalStatus.pending,
                "Previous submission pending"
            );
        }
        submittedProposals.push(
            ProposalSubmission(proposals[_proposalId], block.number)
        );
        submittedProposals[submittedProposals.length - 1]
            .proposalStruct
            .ProposalsubmitedBy = msg.sender;

        for (uint256 i = 0; i < memberCount; i++) {
            memberDetails[i].voteStatus = VoteStatus.active;
        }

        memberDetails[findMemberId()].contributions += msg.value;
    }

    //verify member

    modifier verifyMember() {
        require(!destroyed, "Contract destroyed");
        bool temp;

        for (uint256 i; i < memberCount; i++) {
            if (msg.sender == memberDetails[i].memberAddress) {
                temp = true;
            }
        }

        require(temp == true, "Only accesible to members");
        _;
    }

    modifier submissionStatus() {
        require(submittedProposals.length != 0, "Submissions not found");
        _;
    }

    //Submissions status

    function viewSubmissionStatus()
        public
        view
        submissionStatus
        returns (ProposalStatus)
    {
        require(!destroyed, "Contract destroyed");

        return
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .proposalStatus;
    }

    //Submission votes

    function viewSubmissionVotes()
        public
        view
        submissionStatus
        returns (uint256)
    {
        require(!destroyed, "Contract destroyed");

        return
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .votesReceived;
    }

    //vote

    function upVote() public verifyMember submissionStatus {
        require(!destroyed, "Contract destroyed");

        if (memberDetails[findMemberId()].voteStatus == VoteStatus.voted) {
            revert("Already voted !");
        }
        require(
            memberDetails[findMemberId()].voteStatus == VoteStatus.active,
            "Voting session doesn't exist"
        );
        require(
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .proposalStatus == ProposalStatus.pending,
            "No new submissions to vote for"
        );
        submittedProposals[submittedProposals.length - 1]
            .proposalStruct
            .votesReceived++;
        memberDetails[findMemberId()].voteStatus = VoteStatus.voted;
    }

    //View contract balance

    function viewBalance() public view returns(uint){

        return address(this).balance;
    }

    //Donate function

    bool donateStatus;

    function donate() public payable {
        require(!destroyed, "Contract destroyed");

        require(donateStatus, "Permission denied !");
        payable(charity).transfer(address(this).balance / 10);
    }

    //Result and execution
    function findResult() public submissionStatus {
        require(!destroyed, "Contract destroyed");

        require(
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .proposalStatus == ProposalStatus.pending,
            "No active submissions to find result"
        );
        require(
            block.number -
                submittedProposals[submittedProposals.length - 1].blockNumber >
                10,
            "Time still remaining"
        );

        uint256 votes_received = submittedProposals[
            submittedProposals.length - 1
        ].proposalStruct.votesReceived;
        bool Submission_accepted;
        if (votes_received > (memberCount - votes_received)) {
            Submission_accepted = true;
        } else if (votes_received < (memberCount - votes_received)) {
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .proposalStatus = ProposalStatus.rejected;
        } else {
            submittedProposals[submittedProposals.length - 1]
                .proposalStruct
                .proposalStatus = ProposalStatus.rejected;
        }

        if (Submission_accepted) {
            if (
                submittedProposals[submittedProposals.length - 1]
                    .proposalStruct
                    .proposalName == proposalNames.donate
            ) {
                donateStatus = true;
                donate();
                donateStatus = false;

                for (uint256 i = 0; i < memberCount; i++) {
                    memberDetails[i].voteStatus = VoteStatus.inactive;
                    submittedProposals[submittedProposals.length - 1]
                        .proposalStruct
                        .proposalStatus = ProposalStatus.accepted;
                }
            } else if (
                submittedProposals[submittedProposals.length - 1]
                    .proposalStruct
                    .proposalName == proposalNames.adminChange
            ) {
                newAdmin = true;
                submittedProposals[submittedProposals.length - 1]
                    .proposalStruct
                    .proposalStatus = ProposalStatus.accepted;

                for (uint256 i = 0; i < memberCount; i++) {
                    memberDetails[i].voteStatus = VoteStatus.inactive;
                    submittedProposals[submittedProposals.length - 1]
                        .proposalStruct
                        .proposalStatus = ProposalStatus.accepted;
                }
            } else {
                uint256 Gas = tx.gasprice;
                uint256 dividentAmt = address(this).balance /
                    memberCount -
                    (Gas * (memberCount + 1));

                // Distributing remaining balances among members

                for (uint256 i = 0; i < memberCount; i++) {
                    payable(memberDetails[i].memberAddress).transfer(
                        dividentAmt
                    );
                }

                //Removing members

                for (uint256 i = 0; i < memberCount; i++) {
                    memberDetails[i].memberAddress = address(0);
                }
                submittedProposals[submittedProposals.length - 1]
                    .proposalStruct
                    .proposalStatus = ProposalStatus.accepted;

                memberCount = 0;
                admin = address(0);
                destroyed = true;
            }
        }
    }
}
