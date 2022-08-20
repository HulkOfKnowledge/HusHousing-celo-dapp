// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {
    uint private numberOfHouseAvailable = 0;
    address private cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct House {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        bool sold;
    }

    mapping(uint => House) private houses;

    /// @dev checks if caller is the house owner
    modifier checkIfHouseOwner(uint _index) {
        require(houses[_index].owner == msg.sender, "Unauthorized caller");
        _;
    }

    modifier checkPrice(uint _price) {
        require(_price > 0, "Price must be at least one wei");
        _;
    }

    /// @dev allow users to add a house to the marketplace
    function addHouse(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _location,
        uint _price
    ) public checkPrice(_price) {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image url");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_location).length > 0, "Empty location");
        houses[numberOfHouseAvailable] = House(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            false // sold initialized as false
        );
        numberOfHouseAvailable++;
    }

    function viewHouse(uint _index)
        public
        view
        returns (
            address payable,
            string memory,
            string memory,
            string memory,
            string memory,
            uint,
            bool
        )
    {
        return (
            houses[_index].owner,
            houses[_index].name,
            houses[_index].image,
            houses[_index].description,
            houses[_index].location,
            houses[_index].price,
            houses[_index].sold
        );
    }

    /// @dev allow users to buy a house on sale
    /// @notice current home owners can't buy their own home
    function buyHouse(uint _index) public payable {
        require(
            houses[_index].owner != msg.sender,
            "You can't buy your own houses"
        );
        require(!houses[_index].sold, "House isn't on sale");
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                houses[_index].owner,
                houses[_index].price
            ),
            "Transfer failed."
        );
        houses[_index].owner = payable(msg.sender);
    }

    /// @dev allow users to resell a house
    /// @param _price is the new selling price
    function reSellHouse(uint _index, uint _price)
        public
        payable
        checkIfHouseOwner(_index)
        checkPrice(_price)
    {
        houses[_index].price = _price;
        houses[_index].sold = false;
    }

    /// @dev allow users to cancel a sale on a house
    /// @notice callable only by the home owner
    function cancelSale(uint _index) public payable checkIfHouseOwner(_index) {
        houses[_index].sold = true;
    }

    function viewNumberOfHouseAvailable() public view returns (uint) {
        return (numberOfHouseAvailable);
    }
}
