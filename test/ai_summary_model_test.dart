/*
 *     Copyright (C) 2021  DanXi-Dev
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

import 'package:dan_xi/model/forum/ai_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSummaryResponse', () {
    test('parses a complete JSON response', () {
      final json = <String, dynamic>{
        'code': 1000,
        'message': 'success',
        'data': {
          'hole_id': 42,
          'summary': 'This is a test summary.',
          'branches': [
            {
              'id': 1,
              'label': 'Branch A',
              'content': 'Content of branch A',
              'color': '#FF5733',
              'representative_floors': [1, 5, 10],
            },
          ],
          'interactions': [
            {
              'from_floor': 3,
              'from_user': 'Alice',
              'to_floor': 1,
              'to_user': 'Bob',
              'interaction_type': 'support',
              'content': 'I agree with this.',
            },
          ],
          'keywords': ['flutter', 'dart', 'ai'],
          'generated_at': '2026-03-17T12:00:00Z',
          'cache_expires_at': '2026-03-18T12:00:00Z',
          'is_cached': true,
          'trace_id': 'abc-123-def-456',
        },
      };

      final response = AiSummaryResponse.fromJson(json);

      expect(response.code, 1000);
      expect(response.message, 'success');
      expect(response.data, isNotNull);

      final data = response.data!;
      expect(data.holeId, 42);
      expect(data.summary, 'This is a test summary.');
      expect(data.traceId, 'abc-123-def-456');
      expect(data.isCached, true);
      expect(data.generatedAt, '2026-03-17T12:00:00Z');
      expect(data.cacheExpiresAt, '2026-03-18T12:00:00Z');

      // Branches
      expect(data.branches.length, 1);
      final branch = data.branches.first;
      expect(branch.id, 1);
      expect(branch.label, 'Branch A');
      expect(branch.content, 'Content of branch A');
      expect(branch.color, '#FF5733');
      expect(branch.representativeFloors, [1, 5, 10]);

      // Interactions
      expect(data.interactions.length, 1);
      final interaction = data.interactions.first;
      expect(interaction.fromFloor, 3);
      expect(interaction.fromUser, 'Alice');
      expect(interaction.toFloor, 1);
      expect(interaction.toUser, 'Bob');
      expect(interaction.interactionType, 'support');
      expect(interaction.content, 'I agree with this.');

      // Keywords
      expect(data.keywords, ['flutter', 'dart', 'ai']);
    });

    test('handles missing optional fields gracefully', () {
      final json = <String, dynamic>{
        'code': 1000,
        'data': {
          'hole_id': 7,
          'summary': 'Short summary',
        },
      };

      final response = AiSummaryResponse.fromJson(json);
      expect(response.code, 1000);
      expect(response.message, isNull);

      final data = response.data!;
      expect(data.holeId, 7);
      expect(data.summary, 'Short summary');
      expect(data.traceId, isNull);
      expect(data.branches, isEmpty);
      expect(data.interactions, isEmpty);
      expect(data.keywords, isEmpty);
      expect(data.isCached, isNull);
    });

    test('handles null data field', () {
      final json = <String, dynamic>{
        'code': 2001,
        'message': 'No content available',
      };

      final response = AiSummaryResponse.fromJson(json);
      expect(response.code, 2001);
      expect(response.data, isNull);
    });

    test('parses generating status (1001)', () {
      final json = <String, dynamic>{
        'code': 1001,
        'message': 'Generating',
        'data': {
          'hole_id': 99,
          'trace_id': 'gen-trace-001',
        },
      };

      final response = AiSummaryResponse.fromJson(json);
      expect(response.code, 1001);
      expect(response.data?.traceId, 'gen-trace-001');
      expect(response.data?.summary, isNull);
    });

    test('handles empty JSON', () {
      final response = AiSummaryResponse.fromJson(<String, dynamic>{});
      expect(response.code, isNull);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });
  });

  group('AiSummaryBranch', () {
    test('parses with empty representative_floors', () {
      final json = <String, dynamic>{
        'id': 2,
        'label': 'Empty branch',
        'content': null,
        'color': null,
      };

      final branch = AiSummaryBranch.fromJson(json);
      expect(branch.id, 2);
      expect(branch.label, 'Empty branch');
      expect(branch.content, isNull);
      expect(branch.representativeFloors, isEmpty);
    });
  });

  group('AiSummaryInteraction', () {
    test('parses with minimal fields', () {
      final json = <String, dynamic>{
        'from_floor': 10,
        'interaction_type': 'rebuttal',
      };

      final interaction = AiSummaryInteraction.fromJson(json);
      expect(interaction.fromFloor, 10);
      expect(interaction.interactionType, 'rebuttal');
      expect(interaction.fromUser, isNull);
      expect(interaction.toFloor, isNull);
      expect(interaction.toUser, isNull);
      expect(interaction.content, isNull);
    });
  });
}
