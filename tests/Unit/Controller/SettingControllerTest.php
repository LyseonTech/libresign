<?php

namespace OCA\Libresign\Tests\Unit\Controller;

use OCA\Libresign\Tests\Unit\ApiTestCase;

/**
 * @group DB
 */
final class SettingControllerTest extends ApiTestCase {
	/**
	 * @runInSeparateProcess
	 */
	public function testHasRootCertReturnSuccess() {
		$this->createUser('username', 'password');
		$this->request
			->withRequestHeader([
				'Authorization' => 'Basic ' . base64_encode('username:password')
			])
			->withPath('/setting/has-root-cert');

		$this->assertRequest();
	}
}