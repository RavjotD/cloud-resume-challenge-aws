import json
import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Add lambda directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import counter

class TestLambdaCounter(unittest.TestCase):

    @patch('counter.table')
    def test_counter_increments(self, mock_table):
        # Arrange
        mock_table.get_item.return_value = {
            'Item': {'id': 'visitors', 'count': 5}
        }
        mock_table.update_item.return_value = {}

        # Act
        result = counter.lambda_handler({}, {})

        # Assert
        body = json.loads(result['body'])
        self.assertEqual(body['count'], 6)
        self.assertEqual(result['statusCode'], 200)

    @patch('counter.table')
    def test_returns_correct_status_code(self, mock_table):
        # Arrange
        mock_table.get_item.return_value = {
            'Item': {'id': 'visitors', 'count': 10}
        }
        mock_table.update_item.return_value = {}

        # Act
        result = counter.lambda_handler({}, {})

        # Assert
        self.assertEqual(result['statusCode'], 200)

    @patch('counter.table')
    def test_cors_headers_present(self, mock_table):
        # Arrange
        mock_table.get_item.return_value = {
            'Item': {'id': 'visitors', 'count': 3}
        }
        mock_table.update_item.return_value = {}

        # Act
        result = counter.lambda_handler({}, {})

        # Assert
        self.assertIn('Access-Control-Allow-Origin', result['headers'])
        self.assertEqual(result['headers']['Access-Control-Allow-Origin'], '*')

    @patch('counter.table')
    def test_dynamodb_update_called(self, mock_table):
        # Arrange
        mock_table.get_item.return_value = {
            'Item': {'id': 'visitors', 'count': 7}
        }
        mock_table.update_item.return_value = {}

        # Act
        counter.lambda_handler({}, {})

        # Assert
        mock_table.update_item.assert_called_once()

if __name__ == '__main__':
    unittest.run()