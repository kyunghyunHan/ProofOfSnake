pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProofOfSnake is ERC721 {
//지시자는 라이브러리 함수를 attach 하는 데 사용할 수 있다. 이 함수는 첫 번째 매개변수로 호출된 객체를 받는다.
using SafeMath for uint256;
//최고점수
uint256 public highScore;
//게임비
uint256 public gameFee = 0.1 ether;
//현재 최고 득점자 주소
address public currentLeader;
//소유자의 주소
address public owner;
//현재 최고 득점자와 과거 승자의 수입을 추적하기 위해 potBalance라는 주소 키와 단위 값 쌍이 있는 매핑
mapping(address =>uint256)public potBalance;
//stoped라는 부울은 처음에 false로 설정되었습니다.
bool public stopped = false;
modifier onlyOwner{
    require(msg.sender ==owner);
    _;
}
modifier stopInEmergency {
	require(!stopped);
	_;
}

modifier onlyInEmergency {
	require(stopped);
	_;
}
//소유자만 이함수 호출
function emergency() public onlyOwner {
	if (stopped == false) {
		stopped = true;
	} 
	else {
		stopped = false;
	}
}
//계약소유자의 주
//초기설정
constructor() public ERC721("Proof-of-Snake High Scorer", "POSHS") { 
	owner = msg.sender;
	currentLeader = msg.sender;
	potBalance[owner] = 0;
	highScore = 2;
}
function playGame() public payable stopInEmergency {
	//@notice Ensures minimum value to play the game is met.
	require(msg.value >= gameFee, "Minimum game fee is not met.");
	potBalance[msg.sender] = 0;
    
	//@dev Safety feature: use SafeMath's function to add half the fee to currentLeader's potBalance mapping
	//@dev Safety feature: use SafeMath's functions to add remaining fee to owner's potBalance mapping
	potBalance[owner] = potBalance[owner].add(msg.value.div(2));
	potBalance[currentLeader] = potBalance[currentLeader].add(
	msg.value.sub(msg.value.div(2))
    );
}
function newLeader(uint256 _score) public stopInEmergency {
	//@notice Requires that msg.sender has at least paid to play the game once
	require(potBalance[msg.sender] >= 0, "Player has not played before.");
	//@notice Updates the current leader to msg.sender
	currentLeader = msg.sender;
	//@notice Updates the current high score
	highScore = _score;
    
	//Mint a POSHS token
	uint256 _tokenId = totalSupply().add(1);
	_mint(msg.sender, _tokenId);
}
	function withdrawEarnings() public stopInEmergency {
	//@notice Ensures that withdrawer's high score has been beatan before being able to withdraw. This maintains the intended economics.
	require(
		msg.sender != currentLeader && potBalance[msg.sender] > 0,
		"Leader's high score has not been beaten or no earnings collected yet."
	);

	potBalance[msg.sender] = 0;

	//@notice Empty out balance of msg.sender and transfer to msg.sender.
	msg.sender.transfer(potBalance[msg.sender]);
}	
}