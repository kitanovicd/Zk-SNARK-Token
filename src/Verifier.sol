// SPDX-License-Identifier: UNLICENSED
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
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        return
            G2Point(
                [
                    10857046999023057135944570762232829481370756359578518086990519993285655852781,
                    11559732032986387107991004021392285783925812861821192530917403151452391805634
                ],
                [
                    8495653923123431417604973247489272438418190587263600148770280649306958101930,
                    4082367875863433681332203403145435568316851327593401208105741076214120093531
                ]
            );
    }

    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success);
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(
        G1Point memory p,
        uint s
    ) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success);
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(
        G1Point[] memory p1,
        G2Point[] memory p2
    ) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++) {
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
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
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
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
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
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
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

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(
            uint256(
                0x0ca1a2239bb67abd832ac09b6c5beea32f20154edb81ea923c280ee939814217
            ),
            uint256(
                0x1031728765a1f0b5a7bab256c6b22929f2e13f92735608dafc5083c1dfc83cc4
            )
        );
        vk.beta = Pairing.G2Point(
            [
                uint256(
                    0x2651f15637b2462feba82f849760e3b7b20509e1277fed47e89c4e4c60e17077
                ),
                uint256(
                    0x277f8e2ccc7bc354be5f394f5ebd79b83d69d624b46cd21f5dcd19df258ff7a4
                )
            ],
            [
                uint256(
                    0x0e8fb949481b1c744ebb1af71cf317b0e33aec465cf23a2081955352a0b97fe9
                ),
                uint256(
                    0x0a97c6a0737e4a6490e707dc82fc44e1c9bab18b61a9ad6450be3c3e150b18dd
                )
            ]
        );
        vk.gamma = Pairing.G2Point(
            [
                uint256(
                    0x2d0df854b6f73a47769a2a3cdbf05e70d69de9e35e7c63740c893aab36bae06c
                ),
                uint256(
                    0x257ffe98519082cc9073c8ae043e7e136080d8f6d333e5220fd69f294e29f7f5
                )
            ],
            [
                uint256(
                    0x0327eb0493914e023810fb962f04638b29bd0de2e9cdca53fc1bbcad39a9344f
                ),
                uint256(
                    0x1f34a5523aaef13b40863c980926fa7886bcd802a3f19654d4b713c953e312e2
                )
            ]
        );
        vk.delta = Pairing.G2Point(
            [
                uint256(
                    0x1fc6f041b6b6abd33d8a530331b276e34025c9b33d87082363e0736ad1e96651
                ),
                uint256(
                    0x11d2f15ed198dd2a57528f8b3e93c39658b60d1d354e238f47dfc2ef791ee06c
                )
            ],
            [
                uint256(
                    0x1d0898bdfd398b4989625e11fecdf34809b317fd9002c5045d9809c02fd1a498
                ),
                uint256(
                    0x0d76ec0871b344f42852a50f86b124c7588e8a8c5a11d96a2dbdce89efd1ad79
                )
            ]
        );
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(
            uint256(
                0x0d0eeafba87acda743480a3ec20a60e8d3f948aec403f8f86cb8c24c86f698aa
            ),
            uint256(
                0x0c8db704b1cdba5456272fcc54766e1f0201cc3ada46dd8027cd15ccfa2fafac
            )
        );
        vk.gamma_abc[1] = Pairing.G1Point(
            uint256(
                0x2a24e8cda0f09293a8a36c30018707eb22b224f1e00ee74fff1406e5da897d89
            ),
            uint256(
                0x06918a71fdc2229335a8dae41b3e099a39c473f9705a0f33d0a83187c9e3ac57
            )
        );
        vk.gamma_abc[2] = Pairing.G1Point(
            uint256(
                0x1cc2efb09796c3a0ee61ec616b05a9addc8ed0aeca925c82959ae524340b1b03
            ),
            uint256(
                0x0942945a8478d1515ce60913435e6d4af587f95629050046861aeec45507c074
            )
        );
        vk.gamma_abc[3] = Pairing.G1Point(
            uint256(
                0x275e5e1a75fb4a50f516db3e357471712c82b30446b85f8eb8b3674a73d99df3
            ),
            uint256(
                0x22955507b2bc62cc95d42c9d374710617d095d298f46377fd2d3f37134def19e
            )
        );
        vk.gamma_abc[4] = Pairing.G1Point(
            uint256(
                0x240f02594ecfb615e0a99a621ae57bb42e5d847eee191ccd3207a62f9285a0a0
            ),
            uint256(
                0x050ecd19c88435743469fcb6dc503a7f5abbe8b1d74a710e6d4ded58640e3caa
            )
        );
        vk.gamma_abc[5] = Pairing.G1Point(
            uint256(
                0x193249e000f549988294a3f8943bdd7a56872911914858a2cf85fda78d45fe90
            ),
            uint256(
                0x2b5bebd87cdddd6cc6f9b8152215cd1cba5da2d251c0a8813bd86b9a7ba4473a
            )
        );
        vk.gamma_abc[6] = Pairing.G1Point(
            uint256(
                0x03a118dda34c483a90a5d687fbdacfd6236710995552b84e761d0813861c5000
            ),
            uint256(
                0x0dc808c0bcf20a9d952bf800bd5b1a7446ab1fbcc95ba98a5f8571e4792f117c
            )
        );
    }

    function verify(
        uint[] memory input,
        Proof memory proof
    ) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if (
            !Pairing.pairingProd4(
                proof.a,
                proof.b,
                Pairing.negate(vk_x),
                vk.gamma,
                Pairing.negate(proof.c),
                vk.delta,
                Pairing.negate(vk.alpha),
                vk.beta
            )
        ) return 1;
        return 0;
    }

    function verifyTx(
        Proof memory proof,
        uint[6] memory input
    ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](6);

        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
