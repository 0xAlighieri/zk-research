// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract PairingTest {
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    uint256 constant PRIME_Q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // K1

    uint256 constant k1G1_x = 0;

    uint256 constant k1G1_y = 0;

    // K2

    uint256 constant k2G1_x =
        13528591474082492817989364351907050604558391337621820406021384540557209749643;

    uint256 constant k2G1_y =
        14443303276765745692271933246133099141967259652638964362265269266367251910074;

    // -A

    uint256 constant aG1_x =
        2064430016998063779353798725494295938510033570286085637920979922823529914045;

    uint256 constant aG1_y =
        11163607427677292198086904898742192686118651690403161551689462855076808244786;

    // B

    uint256 constant bG2_x1 =
        9379046325560130406292105118491912585512872816957156094865020637942426737446;

    uint256 constant bG2_x2 =
        18922197764223081518953110924117923760865927663005267733120456934193918085640;

    uint256 constant bG2_y1 =
        19287159416571646716477490319551260722876879850544316937354427240244882161840;

    uint256 constant bG2_y2 =
        3367833720826567747182456585873250679881805484133693446398305445816768906977;

    // alpha

    uint256 constant alphaG1_x =
        1368015179489954701390400359078579693043519447331113978918064868415326638035;

    uint256 constant alphaG1_y =
        9918110051302171585080402603319702774565515993150576347155970296011118125764;

    // beta

    uint256 constant betaG2_x1 =
        2725019753478801796453339367788033689375851816420509565303521482350756874229;

    uint256 constant betaG2_x2 =
        7273165102799931111715871471550377909735733521218303035754523677688038059653;

    uint256 constant betaG2_y1 =
        2512659008974376214222774206987427162027254181373325676825515531566330959255;

    uint256 constant betaG2_y2 =
        957874124722006818841961785324909313781880061366718538693995380805373202866;

    // C

    uint256 constant cG1_x =
        4696614388732208573829558575249298593120327644460963806380152762064195939315;

    uint256 constant cG1_y =
        5640009225556751408734476549072862475628386315255489818368462316990052828449;

    // G2

    uint256 constant G2_x1 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;

    uint256 constant G2_x2 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;

    uint256 constant G2_y1 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    uint256 constant G2_y2 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;

    uint256 one = 1;

    uint256 out = 2;

    struct G2Point {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
    }

    function add(
        G1Point memory p1,
        G1Point memory p2
    ) public view returns (G1Point memory r) {
        (bool ok, bytes memory result) = address(6).staticcall(
            abi.encode(p1.x, p1.y, p2.x, p2.y)
        );

        require(ok, "g1add failed");

        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));

        r = G1Point(x, y);
    }

    function mul(
        G1Point memory p,
        uint256 scalar
    ) public view returns (G1Point memory r) {
        (bool ok, bytes memory result) = address(7).staticcall(
            abi.encode(p.x, p.y, scalar)
        );

        require(ok, "g1mul failed");

        (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));

        r = G1Point(x, y);
    }

    function run(bytes memory input) public view returns (bool) {
        // optional, the precompile checks this too and reverts (with no error) if false, this helps narrow down possible errors

        if (input.length % 192 != 0) revert("Points must be a multiple of 6");

        (bool success, bytes memory data) = address(0x08).staticcall(input);

        if (success) return abi.decode(data, (bool));

        revert("Wrong pairing");
    }

    function emulate() public view returns (bool) {
        G1Point memory A = G1Point(aG1_x, aG1_y);

        G2Point memory B = G2Point(bG2_x1, bG2_x2, bG2_y1, bG2_y2);

        G1Point memory C = G1Point(cG1_x, cG1_y);

        uint256[2] memory input = [one, out];

        return verify(A, B, C, input);
    }

    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1

        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
        }
    }

    function verify(
        G1Point memory A,
        G2Point memory B,
        G1Point memory C,
        uint256[2] memory input
    ) public view returns (bool) {
        G1Point memory k1 = mul(G1Point(k1G1_x, k1G1_y), input[0]);

        G1Point memory k2 = mul(G1Point(k2G1_x, k2G1_y), input[1]);

        G1Point memory K = add(k1, k2);

        // -A * B + alpha * beta + C * 1(G2) + K * 1(G2) = 0

        bytes memory points1 = abi.encode(
            A.x,
            negate(A).y,
            B.x2,
            B.x1,
            B.y2,
            B.y1,
            alphaG1_x,
            alphaG1_y,
            betaG2_x2,
            betaG2_x1,
            betaG2_y2,
            betaG2_y1
        );

        bytes memory points2 = abi.encode(
            C.x,
            C.y,
            G2_x2,
            G2_x1,
            G2_y2,
            G2_y1,
            K.x,
            K.y,
            G2_x2,
            G2_x1,
            G2_y2,
            G2_y1
        );

        bytes memory points = abi.encodePacked(points1, points2);

        return run(points);
    }
}
