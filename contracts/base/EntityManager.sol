// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EntityManager {
    uint16 private _languageType;
    mapping(string => uint16) languages;

    function registerLanguage(string memory language)
        external
        returns (uint256)
    {
        _languageType++;
        require(languages[language] == 0, "Have Register");
        languages[language] = _languageType;
        return _languageType;
    }
}
