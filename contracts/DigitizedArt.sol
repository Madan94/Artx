// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;


interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external payable;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata
    ) external payable;
}


contract DigitizedArt is IERC721 {
    string private _name;
    string private _symbol;
    Art[] public arts;
    uint256 private pendingArtCount;
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownedTokensCount;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => ArtTxn[]) private artTxns;
    uint256 public index;
    struct Art {
        uint256 id;
        string title;
        string description;
        uint256 price;
        string date;
        string authorName;
        address payable author;
        address payable owner;
        uint256 status;
        string image;
    }
    struct ArtTxn {
        uint256 id;
        uint256 price;
        address seller;
        address buyer;
        uint256 txnDate;
        uint256 status;
    }
    //d
    event LogArtSold(
        uint256 _tokenId,
        string _title,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner,
        address _buyer
    );
    event LogArtTokenCreate(
        uint256 _tokenId,
        string _title,
        string _category,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner
    );
    event LogArtResell(uint256 _tokenId, uint256 _status, uint256 _price);

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function createTokenAndSellArt(
        string memory _title,
        string memory _description,
        string memory _date,
        string memory _authorName,
        uint256 _price,
        string memory _image
    ) public {
        require(bytes(_title).length > 0, "The title cannot be empty");
        require(bytes(_date).length > 0, "The Date cannot be empty");
        require(
            bytes(_description).length > 0,
            "The description cannot be empty"
        );
        require(_price > 0, "The price cannot be empty");
        require(bytes(_image).length > 0, "The image cannot be empty");
        Art memory _art = Art({
            id: index,
            title: _title,
            description: _description,
            price: _price,
            date: _date,
            authorName: _authorName,
            author: msg.sender,
            owner: msg.sender,
            status: 1,
            image: _image
        });
        arts.push(_art);
        uint256 tokenId = arts.length - 1;
        _mint(msg.sender, tokenId);
        emit LogArtTokenCreate(
            tokenId,
            _title,
            _date,
            _authorName,
            _price,
            msg.sender,
            msg.sender
        );
        index++;
        pendingArtCount++;
    }

    function buyArt(uint256 _tokenId) public payable {
        (
            uint256 _id,
            string memory _title,
            ,
            uint256 _price,
            uint256 _status,
            ,
            string memory _authorName,
            address _author,
            address payable _current_owner,

        ) = findArt(_tokenId);
        require(_current_owner != address(0), "Cannot be zero address");
        require(msg.sender != address(0), "Cannot be zero address");
        require(msg.sender != _current_owner, "Cannot be current owner");
        require(msg.value >= _price, "Invalid Amount");
        require(arts[_tokenId].owner != address(0), "Cannot be zero address");

        _transfer(_current_owner, msg.sender, _tokenId);
        if (msg.value > _price) msg.sender.transfer(msg.value - _price);
        _current_owner.transfer(_price);
        arts[_tokenId].owner = msg.sender;
        arts[_tokenId].status = 0;
        ArtTxn memory _artTxn = ArtTxn({
            id: _id,
            price: _price,
            seller: _current_owner,
            buyer: msg.sender,
            txnDate: now,
            status: _status
        });
        artTxns[_id].push(_artTxn);
        pendingArtCount--;

        emit LogArtSold(
            _tokenId,
            _title,
            _authorName,
            _price,
            _author,
            _current_owner,
            msg.sender
        );
    }

    function resellArt(uint256 _tokenId, uint256 _price) public payable {
        require(msg.sender != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        arts[_tokenId].status = 1;
        arts[_tokenId].price = _price;
        pendingArtCount++;
        emit LogArtResell(_tokenId, 1, _price);
    }

    function findArt(uint256 _tokenId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            uint256 status,
            string memory,
            string memory,
            address,
            address payable,
            string memory
        )
    {
        Art memory art = arts[_tokenId];
        return (
            art.id,
            art.title,
            art.description,
            art.price,
            art.status,
            art.date,
            art.authorName,
            art.author,
            art.owner,
            art.image
        );
    }

    function findAllArt()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        uint256 arrLength = arts.length;
        uint256[] memory ids = new uint256[](arrLength);
        address[] memory authors = new address[](arrLength);
        address[] memory owners = new address[](arrLength);
        uint256[] memory status = new uint256[](arrLength);
        for (uint256 i = 0; i < arrLength; ++i) {
            Art memory art = arts[i];
            ids[i] = art.id;
            authors[i] = art.author;
            owners[i] = art.owner;
            status[i] = art.status;
        }
        return (ids, authors, owners, status);
    }

    function findAllPendingArt()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        if (pendingArtCount == 0) {
            return (
                new uint256[](0),
                new address[](0),
                new address[](0),
                new uint256[](0)
            );
        } else {
            uint256 arrLength = arts.length;
            uint256[] memory ids = new uint256[](pendingArtCount);
            address[] memory authors = new address[](pendingArtCount);
            address[] memory owners = new address[](pendingArtCount);
            uint256[] memory status = new uint256[](pendingArtCount);
            uint256 idx = 0;
            for (uint256 i = 0; i < arrLength; ++i) {
                Art memory art = arts[i];
                if (art.status == 1) {
                    ids[idx] = art.id;
                    authors[idx] = art.author;
                    owners[idx] = art.owner;
                    status[idx] = art.status;
                    idx++;
                }
            }
            return (ids, authors, owners, status);
        }
    }

    function findMyArts() public view returns (uint256[] memory _myArts) {
        require(msg.sender != address(0), "Cannot be zero address");
        uint256 numOftokens = balanceOf(msg.sender);
        if (numOftokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory myArts = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = arts.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (_tokenOwner[i] == msg.sender) {
                    myArts[idx] = i;
                    idx++;
                }
            }
            return myArts;
        }
    }

    function getArtAllTxn(uint256 _tokenId)
        public
        view
        returns (
            uint256[] memory _id,
            uint256[] memory _price,
            address[] memory seller,
            address[] memory buyer,
            uint256[] memory _txnDate
        )
    {
        ArtTxn[] memory artTxnList = artTxns[_tokenId];
        uint256 arrLength = artTxnList.length;
        uint256[] memory ids = new uint256[](arrLength);
        uint256[] memory prices = new uint256[](arrLength);
        address[] memory sellers = new address[](arrLength);
        address[] memory buyers = new address[](arrLength);
        uint256[] memory txnDates = new uint256[](arrLength);
        for (uint256 i = 0; i < artTxnList.length; ++i) {
            ArtTxn memory artTxn = artTxnList[i];
            ids[i] = artTxn.id;
            prices[i] = artTxn.price;
            sellers[i] = artTxn.seller;
            buyers[i] = artTxn.buyer;
            txnDates[i] = artTxn.txnDate;
        }
        return (ids, prices, sellers, buyers, txnDates);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        _ownedTokensCount[_to]++;
        _ownedTokensCount[_from]--;
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 tokenId) internal {
        require(_to != address(0), "Cannot be zero address");
        require(!_exists(tokenId), "");
        _tokenOwner[tokenId] = _to;
        _ownedTokensCount[_to]++;
        emit Transfer(address(0), _to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return _ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId)
        public
        override
        view
        returns (address _owner)
    {
        _owner = _tokenOwner[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public override payable {
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override payable {
        require(_to != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, _from), "Invalid owner");
        require(isApproved(_to, _tokenId), "Wrong approval");
        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        _transfer(msg.sender, _to, _tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        override
        view
        returns (address)
    {
        require(_exists(tokenId), "Does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        override
    {
        require(operator != msg.sender, "Operator should be current owner");
        _operatorApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        override
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override payable {
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override payable {
    }

    function isOwnerOf(uint256 tokenId, address account)
        public
        view
        returns (bool)
    {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "Cannot be zero address");
        return owner == account;
    }

    function isApproved(address _to, uint256 _tokenId)
        private
        view
        returns (bool)
    {
        return _tokenApprovals[_tokenId] == _to;
    }
}