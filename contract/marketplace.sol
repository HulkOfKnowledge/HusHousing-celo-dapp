// SPDX-License-Identifier: MIT

/// @dev solitity version.
pragma solidity >=0.7.0 <0.9.0; //this contract works for solidty version from 0.7.0 to less than 0.9.0

/**
* @dev REquired interface of an ERC20 compliant contract.
*/
interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

/**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address, uint256) external returns (bool);

 /**
     * @dev Transfers `tokenId` token from `from` to `to`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);


    function totalSupply() external view returns (uint256);

/*
*@dev Returns the number of tokens in``owner``'s acount.
*/
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

/*
*@dev Emitted when `tokenId` token is transferred from `from` to `to`.
*/
    event Transfer(address indexed from, address indexed to, uint256 value);

/*
*@dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
*/  
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {
    uint private numberOfHouseAvailable = 0;

    /// @dev stores the cUsdToken Address
    address private cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

/* @dev House structure 
* data needed includes: 
* - ``owner``'s address,
* - name of house (ie Mansion, duplex, bungalow,...)
* - description of house (ie 4bedrooms, 5restooms, 2 swimming pools,...)
* - location of house (ie CA, USA)
* - price of house
* - sold (A bool variable that intialized to false. When set to true, it means the house has been purchased and is off the market.)
*/
    struct House {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        bool sold;
    }

    /// @dev stores each House created in a list called houses
    mapping(uint => House) private houses;

    /// @dev maps the index of item in houses to a bool value (initialized as false)
    mapping(uint => bool) private exists;

    /// @dev checks if caller is the house owner
    modifier checkIfHouseOwner(uint _index) {
        require(houses[_index].owner == msg.sender, "Unauthorized caller");
        _;
    }

    /// @dev checks price of house is at least one wei
    modifier checkPrice(uint _price) {
        require(_price > 0, "Price must be at least one wei");
        _;
    }

    /// @dev checks houses(_index) exists
    modifier exist(uint _index) {
        require(exists[_index], "Query of nonexistent house");
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
         exists[numberOfHouseAvailable] = true;
        numberOfHouseAvailable++;
    }

    /// @dev allow users view details of House
    function viewHouse(uint _index)
        public
        view
        exist(_index)
        returns (House memory)
    {
        return (houses[_index]);
    }

    /// @dev allow users to buy a house on sale
    /// @notice current home owners can't buy their own home
    function buyHouse(uint _index) external payable exist(_index) {
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
        exist(_index)
        checkIfHouseOwner(_index)
        checkPrice(_price)
    {
        houses[_index].price = _price;
        houses[_index].sold = false;
    }

    /// @dev allow users to cancel a sale on a house
    /// @notice callable only by the home owner
    function cancelSale(uint _index)
        public
        payable
        exist(_index)
        checkIfHouseOwner(_index)
    {
        houses[_index].sold = true;
    }


    /// @dev shows the number of houses in the contract
    function viewNumberOfHouseAvailable() public view returns (uint) {
        return (numberOfHouseAvailable);
    }
}