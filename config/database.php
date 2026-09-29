<?php

declare(strict_types=1);

namespace App\Config;

class Database
{
    private static ?Database $instance = null;
    private \PDO $pdo;

    private const DB_HOST = 'sql104.infinityfree.com';
    private const DB_PORT = '3306';
    private const DB_NAME = 'if0_42234715_ebook_library';
    private const DB_USER = 'if0_42234715';
    private const DB_PASS = 'aaBB4321';

    private function __construct()
    {
        $host = getenv('DB_HOST') ?: self::DB_HOST;
        $port = getenv('DB_PORT') ?: self::DB_PORT;
        $name = getenv('DB_NAME') ?: self::DB_NAME;
        $user = getenv('DB_USER') ?: self::DB_USER;
        $pass = getenv('DB_PASS') ?: self::DB_PASS;

        $this->pdo = new \PDO(
            "mysql:host=$host;port=$port;dbname=$name;charset=utf8mb4",
            $user,
            $pass,
            [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
                \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
                \PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
    }

    public static function connect(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function pdo(): \PDO
    {
        return $this->pdo;
    }

    public function query(string $sql, array $params = []): \PDOStatement
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public function fetchAll(string $sql, array $params = []): array
    {
        return $this->query($sql, $params)->fetchAll();
    }

    public function fetchOne(string $sql, array $params = []): ?array
    {
        $row = $this->query($sql, $params)->fetch();
        return $row ?: null;
    }

    public function execute(string $sql, array $params = []): int
    {
        $this->query($sql, $params);
        return (int) $this->pdo->lastInsertId();
    }
}
