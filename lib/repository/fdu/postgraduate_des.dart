/*
 *     Copyright (C) 2026  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/// Native Dart implementation of the password encryption used by
/// the postgraduate course selection system (yjsxk.fudan.sh.cn).
///
/// This is a **non-standard Triple DES variant**:
/// - Data encoding: each character is represented as 16 bits (UTF-16 code unit),
///   so 4 characters = 64 bits = one DES block.
/// - Triple mode: EEE (three forward encryptions) instead of standard 3DES EDE.
/// - Fixed keys: "1", "2", "3".
/// - Key schedule: the PC-1 D-half (indices 28–55) uses a column-major
///   ascending layout instead of the standard DES descending layout.
///   All other primitives (PC-2, IP, IP⁻¹, E expansion, S-Boxes,
///   P permutation) follow standard DES.
class PostgraduateDES {
  PostgraduateDES._();

  // ==================== Lookup Tables ====================

  /// Eight S-Boxes, each 4×16. Standard DES S-Boxes.
  static const List<List<List<int>>> _sBoxes = [
    // S1
    [
      [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
      [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
      [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
      [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
    ],
    // S2
    [
      [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
      [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
      [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
      [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],
    ],
    // S3
    [
      [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
      [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
      [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
      [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],
    ],
    // S4
    [
      [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
      [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
      [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
      [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],
    ],
    // S5
    [
      [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
      [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
      [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
      [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3],
    ],
    // S6
    [
      [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
      [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
      [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
      [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13],
    ],
    // S7
    [
      [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
      [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
      [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
      [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12],
    ],
    // S8
    [
      [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
      [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
      [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
      [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11],
    ],
  ];

  /// P permutation table (0-indexed).
  static const List<int> _pPermutation = [
    15, 6, 19, 20, 28, 11, 27, 16,
    0, 14, 22, 25, 4, 17, 30, 9,
    1, 7, 23, 13, 31, 26, 2, 8,
    18, 12, 29, 5, 21, 10, 3, 24,
  ];

  /// PC-2 selection permutation indices (0-indexed).
  /// Selects 48 bits from the 56-bit key state to form each sub-key.
  static const List<int> _pc2 = [
    13, 16, 10, 23, 0, 4, 2, 27,
    14, 5, 20, 9, 22, 18, 11, 3,
    25, 7, 15, 6, 26, 19, 12, 1,
    40, 51, 30, 36, 46, 54, 29, 39,
    50, 44, 32, 47, 43, 48, 38, 55,
    33, 52, 45, 41, 49, 35, 28, 31,
  ];

  /// Number of left shifts per round in the key schedule.
  static const List<int> _keyShifts = [
    1, 1, 2, 2, 2, 2, 2, 2,
    1, 2, 2, 2, 2, 2, 2, 1,
  ];

  // ==================== Public API ====================

  /// Encryption entry point. Equivalent to the JS function `o(plaintext)`.
  ///
  /// Encrypts [plaintext] using Triple DES (EEE mode) with fixed keys
  /// "1", "2", "3" and returns an uppercase hexadecimal string.
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    return _tripleDesEncrypt(plaintext, '1', '2', '3');
  }

  // ==================== Internal Implementation ====================

  /// Triple DES encryption (EEE mode): encrypts sequentially with
  /// [key1], [key2], and [key3].
  /// Equivalent to the JS function `d(X, Q, B, E)`.
  static String _tripleDesEncrypt(
      String plaintext, String key1, String key2, String key3) {
    final keys1 = _splitKey(key1);
    final keys2 = _splitKey(key2);
    final keys3 = _splitKey(key3);

    final result = StringBuffer();
    final len = plaintext.length;
    final fullBlocks = len ~/ 4;
    final remainder = len % 4;

    for (int i = 0; i < fullBlocks; i++) {
      final blockStr = plaintext.substring(i * 4, i * 4 + 4);
      var block = _textToBlock(blockStr);
      block = _applyKeys(block, keys1);
      block = _applyKeys(block, keys2);
      block = _applyKeys(block, keys3);
      result.write(_blockToHex(block));
    }

    if (remainder > 0) {
      final blockStr = plaintext.substring(fullBlocks * 4, len);
      var block = _textToBlock(blockStr);
      block = _applyKeys(block, keys1);
      block = _applyKeys(block, keys2);
      block = _applyKeys(block, keys3);
      result.write(_blockToHex(block));
    }

    return result.toString();
  }

  /// Applies DES encryption sequentially with each key block.
  static List<int> _applyKeys(List<int> block, List<List<int>> keyBlocks) {
    var result = block;
    for (final keyBlock in keyBlocks) {
      result = _desEncryptBlock(result, keyBlock);
    }
    return result;
  }

  /// Splits a key string into 64-bit blocks (4 characters each).
  /// Equivalent to the JS function `r(E)`.
  static List<List<int>> _splitKey(String key) {
    final result = <List<int>>[];
    final len = key.length;
    final fullBlocks = len ~/ 4;
    final remainder = len % 4;

    for (int i = 0; i < fullBlocks; i++) {
      result.add(_textToBlock(key.substring(i * 4, i * 4 + 4)));
    }
    if (remainder > 0) {
      result.add(_textToBlock(key.substring(fullBlocks * 4, len)));
    }
    return result;
  }

  /// Converts up to 4 characters into a 64-bit binary array.
  /// Each character is represented as 16 bits (UTF-16 code unit);
  /// positions beyond the string length are zero-padded.
  /// Equivalent to the JS function `a(J)`.
  static List<int> _textToBlock(String text) {
    final block = List<int>.filled(64, 0);
    final charCount = text.length < 4 ? text.length : 4;

    for (int h = 0; h < charCount; h++) {
      final charCode = text.codeUnitAt(h);
      for (int g = 0; g < 16; g++) {
        // Extract the g-th bit (MSB first)
        block[16 * h + g] = (charCode >> (15 - g)) & 1;
      }
    }
    // Remaining positions are already 0 (List.filled(64, 0))
    return block;
  }

  /// Single DES encryption (16-round Feistel network).
  /// Equivalent to the JS function `e(C, M)`.
  static List<int> _desEncryptBlock(List<int> block, List<int> key) {
    final subKeys = _keySchedule(key);
    final permuted = _initialPermutation(block);

    final left = List<int>.from(permuted.sublist(0, 32));
    final right = List<int>.from(permuted.sublist(32, 64));

    for (int round = 0; round < 16; round++) {
      final prevLeft = List<int>.from(left);

      // L = R
      for (int j = 0; j < 32; j++) {
        left[j] = right[j];
      }

      // R = P(S(E(R) XOR K)) XOR L_prev
      final expanded = _expand(right);
      final xored = _xor(expanded, subKeys[round]);
      final substituted = _sBoxSubstitute(xored);
      final permutedP = _pPermute(substituted);
      final newRight = _xor(permutedP, prevLeft);

      for (int j = 0; j < 32; j++) {
        right[j] = newRight[j];
      }
    }

    // Final swap: output = R || L
    final preOutput = List<int>.filled(64, 0);
    for (int i = 0; i < 32; i++) {
      preOutput[i] = right[i];
      preOutput[32 + i] = left[i];
    }

    return _finalPermutation(preOutput);
  }

  /// Key schedule: generates 16 round sub-keys of 48 bits each.
  /// Equivalent to the JS function `w(D)`.
  ///
  /// Note: PC-1 D-half differs from standard DES (ascending column-major).
  static List<List<int>> _keySchedule(List<int> key) {
    // PC-1: permute 64-bit key down to 56 bits
    final state = List<int>.filled(56, 0);
    for (int e = 0; e < 7; e++) {
      for (int j = 0, k = 7; j < 8; j++, k--) {
        state[e * 8 + j] = key[8 * k + e];
      }
    }

    final subKeys = List<List<int>>.generate(16, (_) => List<int>.filled(48, 0));

    for (int round = 0; round < 16; round++) {
      // Left rotate
      for (int j = 0; j < _keyShifts[round]; j++) {
        final topC = state[0];
        final topD = state[28];
        for (int k = 0; k < 27; k++) {
          state[k] = state[k + 1];
          state[28 + k] = state[29 + k];
        }
        state[27] = topC;
        state[55] = topD;
      }

      // PC-2: select 48 bits from 56
      for (int m = 0; m < 48; m++) {
        subKeys[round][m] = state[_pc2[m]];
      }
    }

    return subKeys;
  }

  /// Initial Permutation (IP), standard DES.
  /// Equivalent to the JS function `z(C)`.
  static List<int> _initialPermutation(List<int> block) {
    final result = List<int>.filled(64, 0);
    for (int i = 0, m = 1, n = 0; i < 4; i++, m += 2, n += 2) {
      for (int j = 7, k = 0; j >= 0; j--, k++) {
        result[i * 8 + k] = block[j * 8 + m];
        result[i * 8 + k + 32] = block[j * 8 + n];
      }
    }
    return result;
  }

  /// Final Permutation (IP⁻¹), standard DES.
  /// Equivalent to the JS function `y(B)`.
  static List<int> _finalPermutation(List<int> block) {
    // Direct lookup table, exactly matching JS function y()
    return [
      block[39], block[7], block[47], block[15],
      block[55], block[23], block[63], block[31],
      block[38], block[6], block[46], block[14],
      block[54], block[22], block[62], block[30],
      block[37], block[5], block[45], block[13],
      block[53], block[21], block[61], block[29],
      block[36], block[4], block[44], block[12],
      block[52], block[20], block[60], block[28],
      block[35], block[3], block[43], block[11],
      block[51], block[19], block[59], block[27],
      block[34], block[2], block[42], block[10],
      block[50], block[18], block[58], block[26],
      block[33], block[1], block[41], block[9],
      block[49], block[17], block[57], block[25],
      block[32], block[0], block[40], block[8],
      block[48], block[16], block[56], block[24],
    ];
  }

  /// E expansion permutation: 32 bits → 48 bits (standard DES).
  /// Equivalent to the JS function `x(B)`.
  static List<int> _expand(List<int> half) {
    final result = List<int>.filled(48, 0);
    for (int i = 0; i < 8; i++) {
      result[i * 6 + 0] = i == 0 ? half[31] : half[i * 4 - 1];
      result[i * 6 + 1] = half[i * 4 + 0];
      result[i * 6 + 2] = half[i * 4 + 1];
      result[i * 6 + 3] = half[i * 4 + 2];
      result[i * 6 + 4] = half[i * 4 + 3];
      result[i * 6 + 5] = i == 7 ? half[0] : half[i * 4 + 4];
    }
    return result;
  }

  /// S-Box substitution: 48 bits → 32 bits (standard DES).
  /// Equivalent to the JS function `s(D)`.
  static List<int> _sBoxSubstitute(List<int> input) {
    final result = List<int>.filled(32, 0);
    for (int m = 0; m < 8; m++) {
      final row = input[m * 6] * 2 + input[m * 6 + 5];
      final col = input[m * 6 + 1] * 8 +
          input[m * 6 + 2] * 4 +
          input[m * 6 + 3] * 2 +
          input[m * 6 + 4];
      final val = _sBoxes[m][row][col];
      result[m * 4 + 0] = (val >> 3) & 1;
      result[m * 4 + 1] = (val >> 2) & 1;
      result[m * 4 + 2] = (val >> 1) & 1;
      result[m * 4 + 3] = val & 1;
    }
    return result;
  }

  /// P permutation: 32 bits → 32 bits (standard DES).
  /// Equivalent to the JS function `t(C)`.
  static List<int> _pPermute(List<int> input) {
    final result = List<int>.filled(32, 0);
    for (int i = 0; i < 32; i++) {
      result[i] = input[_pPermutation[i]];
    }
    return result;
  }

  /// XOR two bit arrays of equal length.
  /// Equivalent to the JS function `u(D, C)`.
  static List<int> _xor(List<int> a, List<int> b) {
    final result = List<int>.filled(a.length, 0);
    for (int i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  /// Converts a 64-bit block into a 16-character uppercase hex string.
  /// Equivalent to the JS functions `f(D)` + `b()`.
  static String _blockToHex(List<int> block) {
    const hexChars = '0123456789ABCDEF';
    final buf = StringBuffer();
    for (int i = 0; i < 16; i++) {
      final nibble = block[i * 4] * 8 +
          block[i * 4 + 1] * 4 +
          block[i * 4 + 2] * 2 +
          block[i * 4 + 3];
      buf.write(hexChars[nibble]);
    }
    return buf.toString();
  }
}
