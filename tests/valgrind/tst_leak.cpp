#include <QtTest>
#include <QObject>


class SomeObject
{
public :
    SomeObject() {}

    int number() const { return 5; }

};

class LeakTest: public QObject
{
    Q_OBJECT

public:
    explicit LeakTest(QObject *parent = nullptr):
        QObject(parent)
    {
    }

private Q_SLOTS:
    void test();
};

void LeakTest::test()
{
    SomeObject *object = new SomeObject(); // Don't free the pointer -> memory leak
    Q_UNUSED(object);
}

QTEST_APPLESS_MAIN(LeakTest)

#include "tst_leak.moc"
