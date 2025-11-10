export default {
  shouldRender(args, component) {
    const composer = args.model;
    return (
      composer &&
      composer.topic &&
      composer.topic.hoojahEnabled &&
      composer.action === "reply"
    );
  },

  setupComponent(args, component) {
    component.set("shouldShowStanceSelector", this.shouldRender(args, component));
  },

  actions: {
    setStance(stance) {
      const composer = this.args.model;
      if (composer) {
        composer.set("hoojahStance", stance);
      }
    },
  },
};
