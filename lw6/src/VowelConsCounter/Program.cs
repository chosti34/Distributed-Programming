﻿using System;
using System.Collections.Generic;
using System.Text;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using StackExchange.Redis;

namespace VowelConsCounter
{
	class Program
	{
		private static readonly HashSet<char> VOWELS = new HashSet<char>
		{
			'a', 'e', 'i', 'o', 'u', 'y'
		};

		private static readonly HashSet<char> CONSONANTS = new HashSet<char>
		{
			'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n',
			'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'z'
		};

		private static ConnectionMultiplexer RedisConnection => ConnectionMultiplexer.Connect("localhost");

		private static int CalculateDatabaseId(string key)
		{
			int hash = 0;
			foreach (char ch in key)
			{
				hash += ch;
			}
			return hash % 16;
		}

		private static string GetValueFromRedis(string key, int databaseId = 0)
		{
			IDatabase database = RedisConnection.GetDatabase(databaseId);
			return database.StringGet(key);
		}

		private static void CountVowelsAndConsonants(string text, out int vowels, out int consonants)
		{
			int vowelsCount = 0;
			int consonantsCount = 0;

			foreach (char ch in text)
			{
				if (VOWELS.Contains(Char.ToLower(ch)))
				{
					++vowelsCount;
				}
				else if (CONSONANTS.Contains(Char.ToLower(ch)))
				{
					++consonantsCount;
				}
			}

			vowels = vowelsCount;
			consonants = consonantsCount;
		}

		public static void Main(string[] args)
		{
			Console.WriteLine("VowelConsCounter");

			var factory = new ConnectionFactory() { HostName = "localhost" };
			using (var connection = factory.CreateConnection())
			{
				using (var channel = connection.CreateModel())
				{
					channel.ExchangeDeclare("text-rank-tasks", ExchangeType.Direct);

					channel.QueueDeclare(
						queue: "count-task",
						durable: false,
						exclusive: false,
						autoDelete: false,
						arguments: null);
					channel.QueueBind(
						queue: "count-task",
						exchange: "text-rank-tasks",
						routingKey: "text-rank-task");

					channel.ExchangeDeclare("vowel-cons-counter", ExchangeType.Direct);

					var consumer = new EventingBasicConsumer(channel);
					consumer.Received += (model, ea) => {
						var body = ea.Body;
						var message = Encoding.UTF8.GetString(body);
						var splitted = message.Split(':');

						Console.WriteLine(message);

						if (splitted.Length == 2 && splitted[0] == "TextRankTask")
						{
							int databaseId = CalculateDatabaseId(splitted[1]);
							Console.WriteLine("Redis database get #" + databaseId + ": " + splitted[1]);
							CountVowelsAndConsonants(
								GetValueFromRedis("TextContent:" + splitted[1], databaseId) ?? "",
								out int vowels, out int consonants);

							channel.BasicPublish(
								exchange: "vowel-cons-counter",
								routingKey: "vowel-cons-task",
								basicProperties: null,
								body: Encoding.UTF8.GetBytes("VowelConsCounted:" + splitted[1] + ":" + vowels + ":" + consonants));
						}
					};

					channel.BasicConsume(
						queue: "count-task",
						autoAck: true,
						consumer: consumer);

					Console.ReadLine();
				}
			}
		}
	}
}
