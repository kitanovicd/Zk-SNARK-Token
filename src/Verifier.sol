// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x08a5e466ff7f7ef719833afb8c102cb9ef2878e37f01643c5488ff30909f4224), uint256(0x2289fdf220935a76caa8723b567b938000fa519b31f2f4f50db9ccd02e206fb0));
        vk.beta = Pairing.G2Point([uint256(0x29155fa5134f556fc435a8d8d3627c588679c39833d70e053fafa9605e4af293), uint256(0x19f5e6760de003abe5c39dff740fd4135bbce4e96850361e29305d405b15bd4f)], [uint256(0x28d449538bf34f49f4f46e5361c4e429cf55c5113e8c6e045b8a106fb8358813), uint256(0x20e7f9cba14f7957349d6577cfcd83d9870b0694259a2506c394073270cac446)]);
        vk.gamma = Pairing.G2Point([uint256(0x04dbb6f0641b27bf2d3105d27750f97d03f3aeeeb1286e65f8063746cc6cbc40), uint256(0x243584d92b86e076ebfa88de782571d9234b04d4401b5d78fe4b3f659bbe96f7)], [uint256(0x1d69b1862962f011b56a5e26fcba3241df7405a534469e8993b9a79701e59fca), uint256(0x0a9e5c0a1f8f1dda04ce00ef5cfb3d4d9f72ee9543782c7fe785d84bde96cd20)]);
        vk.delta = Pairing.G2Point([uint256(0x053355f57c0298edd221f6aa184088cf4aa57b15c3564e35086d7a2ceab4bdf6), uint256(0x2a318988e0d4659b98d53eeea8e244c0aeefd15cbce97636b8cb7ecda466efd8)], [uint256(0x0dfdbb26acb1edaa2cbb1986af98c8e5ffa825dcce4f6a14d9f5b83fe7446775), uint256(0x1ed5a2c293bc4f0ad907196a8ff0659e2f44abb027c8b4d3777f35717c45868f)]);
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1a87bdd167810be058f8df6a726da5c4191b7ba537b66a428b647b8ac5406318), uint256(0x0904dc5dfed5e3f9488e4e26936193197edf395e451ebf7bdb7d482030720aab));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x056d29a5c3aaa87932ecdaeb937ade8d064eb1fde5a8ce165e5eed2f85ac3b15), uint256(0x1fe3249494b88315f7c6b85a18c8daf4cf49e95f2fc3cefde0f69e2ff8188eff));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x165971f178629cf6e05e4f0051985e5953a4d1fc13b4fb7e1ed855eb65a09c41), uint256(0x23546ae755b6cd9cdbc65a4839ff7ab2a0a2ebd5fcb22f2023330b982d6edd92));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x28a098d5066ac66c5ac7bac815df75fbe1eb9dae141ecfe0d29a01d4cff8bac7), uint256(0x14dcb518486dca5785710a4ad7e2527a61205d9cb568cf0d252712bf374561ac));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x10efdcc9329184688b5ccc12e653c866252087588861213c8d2c632a0b80e92d), uint256(0x202ba04322d9154b8637322c73d008d881ce50e3625f69dad46a88ba4a1b0533));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x27d36a1cee9b012f8f55a1835af3183729fa30b608e6dea6d6d0445e74e7447d), uint256(0x1a0fd88d8bb9e1a311e78f3e414f8c5322794b1f34af288d66837ab5eb09a9f2));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x111df66bab72c7c6593e62836ab83699827676310a494ff9805c7528f2dd407b), uint256(0x10219211d115fc2bdc9e048539bc6e4638f0f330bcf42c8d3052215f5825ec02));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[6] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](6);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
