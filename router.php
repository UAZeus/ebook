<?php

declare(strict_types=1);

// Local dev defaults (override with env vars if needed)
putenv('DB_HOST=' . (getenv('DB_HOST') ?: 'localhost'));
putenv('DB_PORT=' . (getenv('DB_PORT') ?: '3306'));
putenv('DB_NAME=' . (getenv('DB_NAME') ?: 'ebook_library'));
putenv('DB_USER=' . (getenv('DB_USER') ?: 'root'));
putenv('DB_PASS=' . (getenv('DB_PASS') ?: '123'));

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = rtrim($uri, '/');

// Block sensitive paths
if (preg_match('#^/(partials|config|database|vendor)(/|$)#', $uri)) {
    http_response_code(404);
    echo 'Not Found';
    return true;
}

// API routing
if (str_starts_with($uri, '/api')) {
    require __DIR__ . '/api/index.php';
    return true;
}

// Clean URL routes
$cleanRoutes = [
    '/login'      => '/login.php',
    '/register'   => '/register.php',
    '/account'    => '/account.php',
    '/activity'   => '/activity.php',
    '/admin'      => '/admin.php',
    '/preferences' => '/preferences.php',
    '/upload'     => '/upload.php',
    '/logout'     => '/logout.php',
];

if (isset($cleanRoutes[$uri])) {
    $_SERVER['SCRIPT_NAME'] = $cleanRoutes[$uri];
    require __DIR__ . $cleanRoutes[$uri];
    return true;
}

// Book route
if (preg_match('#^/book/(\d+)$#', $uri, $m)) {
    $_GET['id'] = $m[1];
    $_SERVER['SCRIPT_NAME'] = '/book.php';
    require __DIR__ . '/book.php';
    return true;
}

// Root
if ($uri === '' || $uri === '/') {
    $_SERVER['SCRIPT_NAME'] = '/index.php';
    require __DIR__ . '/index.php';
    return true;
}

// Serve existing files (CSS, JS, uploads, etc.)
$filePath = __DIR__ . $uri;
if (is_file($filePath)) {
    return false; // Let PHP server handle it
}

// 404
http_response_code(404);
echo 'Not Found';
return true;
