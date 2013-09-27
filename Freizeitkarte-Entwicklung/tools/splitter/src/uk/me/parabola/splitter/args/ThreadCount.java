package uk.me.parabola.splitter.args;

/**
 * @author Chris Miller
 */
public class ThreadCount {
	private final int count;
	private final boolean auto;

	public ThreadCount(int count, boolean isAuto) {
		this.count = count;
		auto = isAuto;
	}

	public int getCount() {
		return count;
	}

	public boolean isAuto() {
		return auto;
	}

	@Override
	public String toString() {
		if (auto) {
			return count + " (auto)";
		} else {
			return String.valueOf(count);
		}
	}
}
