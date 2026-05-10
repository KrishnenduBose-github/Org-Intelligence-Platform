@IsTest
private class OIP_AccessExceptionTest {
    @IsTest
    static void testThrowAccessException() {
        try {
            throw new OIP_AccessException('Access denied');
        } catch (OIP_AccessException e) {
            System.assertEquals('Access denied', e.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    static void testAccessExceptionMessage() {
        OIP_AccessException e = new OIP_AccessException('No permission');
        System.assertEquals('No permission', e.getMessage(), 'Message should match');
        System.assertNotEquals(null, e, 'Exception should not be null');
    }
}